#![cfg(test)]

use crate::{AppState, app, pages};
use axum::{
    Router,
    body::{Body, to_bytes},
    http::{HeaderMap, Request, StatusCode, header},
    response::IntoResponse,
};
use axum_extra::extract::{
    SignedCookieJar,
    cookie::{Cookie, Key},
};
use serde::Serialize;
use similar_asserts::assert_eq;
use std::{collections::BTreeMap, fs, io::Read};
use tempfile::TempDir;
use tower::ServiceExt;

const PASS: &str = "hunter2";

struct Site {
    app: Router,
    key: Key,
    _dir: TempDir,
}

fn site() -> Site {
    let dir = TempDir::new().unwrap();
    for (album, files) in [
        ("misc", &["b.jpg", "a.jpg", "\u{fc}.jpg"][..]),
        ("2024-05-01_berlin", &["x.jpg"]),
        ("2025-01-02_paris", &[]),
    ] {
        for kind in ["fullsize", "preview"] {
            fs::create_dir_all(dir.path().join(kind).join(album)).unwrap();
            for f in files {
                fs::write(
                    dir.path().join(kind).join(album).join(f),
                    format!("{kind} {f}"),
                )
                .unwrap();
            }
        }
    }
    fs::write(dir.path().join("fullsize/.gitkeep"), "").unwrap();
    let key = Key::generate();
    let state = AppState {
        key: key.clone(),
        pass: PASS.into(),
        photos: dir.path().into(),
    };
    Site {
        app: app(state),
        key,
        _dir: dir,
    }
}

struct Res {
    status: StatusCode,
    headers: HeaderMap,
    body: Vec<u8>,
}

// a response as a snapshot: the html body (without the shared <head>) is
// split into one tag per line
#[derive(Serialize)]
struct Snap {
    status: u16,
    headers: BTreeMap<String, String>,
    body: Vec<String>,
}

impl Res {
    fn text(&self) -> String {
        String::from_utf8(self.body.clone()).unwrap()
    }

    fn header_map(&self) -> BTreeMap<String, String> {
        self.headers
            .iter()
            .map(|(k, v)| (k.to_string(), v.to_str().unwrap().into()))
            .collect()
    }

    fn snap(&self) -> Snap {
        let text = self.text();
        let body = text
            .split_once("<body>")
            .map_or("", |(_, b)| b.trim_end_matches("</body></html>"));
        Snap {
            status: self.status.as_u16(),
            headers: self.header_map(),
            body: body
                .replace("><", ">\n<")
                .lines()
                .map(String::from)
                .collect(),
        }
    }
}

// replaces the signed value and the expiry date of a set-cookie header
fn redact_cookie() -> insta::internals::Redaction {
    insta::dynamic_redaction(|v, _| {
        let (value, attrs) = v.as_str().unwrap().split_once(';').unwrap();
        let value = if value == "session=" {
            value
        } else {
            "session=[value]"
        };
        let attrs = attrs.split_once("; Expires=").map_or_else(
            || attrs.to_string(),
            |(a, _)| format!("{a}; Expires=[date]"),
        );
        format!("{value};{attrs}")
    })
}

async fn send(s: &Site, req: Request<Body>) -> Res {
    let res = s.app.clone().oneshot(req).await.unwrap();
    let (parts, body) = res.into_parts();
    Res {
        status: parts.status,
        headers: parts.headers,
        body: to_bytes(body, usize::MAX).await.unwrap().to_vec(),
    }
}

async fn get(s: &Site, uri: &str, cookie: Option<&str>) -> Res {
    let mut req = Request::get(uri);
    if let Some(c) = cookie {
        req = req.header(header::COOKIE, c);
    }
    send(s, req.body(Body::empty()).unwrap()).await
}

async fn login(s: &Site, pass: &str, next: &str) -> Res {
    let req = Request::post("/login")
        .header(header::CONTENT_TYPE, "application/x-www-form-urlencoded")
        .body(Body::from(format!("password={pass}&next={next}")))
        .unwrap();
    send(s, req).await
}

fn set_cookie(r: &Res) -> String {
    let v = r.headers[header::SET_COOKIE].to_str().unwrap();
    v.split(';').next().unwrap().to_string()
}

async fn session(s: &Site) -> String {
    set_cookie(&login(s, PASS, "/photo").await)
}

// a validly signed session cookie with the given value
fn signed(s: &Site, value: &str) -> String {
    let jar = SignedCookieJar::new(s.key.clone()).add(Cookie::new("session", value.to_string()));
    let res = (jar, ()).into_response();
    let v = res.headers()[header::SET_COOKIE].to_str().unwrap();
    v.split(';').next().unwrap().to_string()
}

#[tokio::test]
async fn index() {
    let s = site();
    insta::assert_yaml_snapshot!(get(&s, "/", None).await.snap(), @r#"
    status: 200
    headers:
      content-length: "474"
      content-type: text/html; charset=utf-8
    body:
      - ctrl.sn<ul>
      - "<li>"
      - "<a href=\"/about\">about</a>"
      - "</li>"
      - "<li>"
      - "<a href=\"/photo\">photo</a>"
      - "</li>"
      - "</ul>"
      - "<p>last updated: 2026-10-30</p>"
    "#);
}

#[tokio::test]
async fn about() {
    let s = site();
    insta::assert_yaml_snapshot!(get(&s, "/about", None).await.snap(), @r#"
    status: 200
    headers:
      content-length: "686"
      content-type: text/html; charset=utf-8
    body:
      - "<a href=\"/\">ctrl.sn</a> <span class=\"sep\">•</span> about<br>"
      - "<img id=\"pfp\" src=\"/static/assets/pfp.gif\">"
      - "<ul>"
      - "<li>"
      - "<a href=\"mailto:x@ctrl.sn\">email</a>"
      - "</li>"
      - "<li>"
      - "<a href=\"https://t.me/anuramat\">tg</a>"
      - "</li>"
      - "<li>"
      - "<a href=\"https://github.com/anuramat\">github</a>"
      - "</li>"
      - "<li>"
      - "<a href=\"https://instagram.com/anuramat\">ig</a>"
      - "</li>"
      - "</ul>"
    "#);
}

#[tokio::test]
async fn static_files() {
    let s = site();
    let r = get(&s, "/static/css/main.css", None).await;
    assert_eq!(r.body, fs::read("static/css/main.css").unwrap());
    let mut got = vec![];
    for uri in [
        "/static/css/main.css",
        "/static/js/fslightbox.js",
        "/static/css/modern-normalize.css",
        "/static/nope.css",
        "/static/../Cargo.toml",
    ] {
        let r = get(&s, uri, None).await;
        got.push((uri, r.status, r.headers.get(header::CONTENT_TYPE).cloned()));
    }
    let mime = |m| Some(header::HeaderValue::from_static(m));
    let html = mime("text/html; charset=utf-8");
    assert_eq!(
        got,
        [
            ("/static/css/main.css", StatusCode::OK, mime("text/css")),
            (
                "/static/js/fslightbox.js",
                StatusCode::OK,
                mime("text/javascript")
            ),
            (
                "/static/css/modern-normalize.css",
                StatusCode::OK,
                mime("text/css")
            ),
            ("/static/nope.css", StatusCode::NOT_FOUND, html.clone()),
            ("/static/../Cargo.toml", StatusCode::NOT_FOUND, html),
        ]
    );
}

#[tokio::test]
async fn static_revalidation() {
    let s = site();
    let revalidate = async |uri: &str, etag: &str| {
        let req = Request::get(uri).header(header::IF_NONE_MATCH, etag);
        send(&s, req.body(Body::empty()).unwrap()).await
    };
    for uri in ["/static/css/main.css", "/static/js/fslightbox.js"] {
        let etag = get(&s, uri, None).await.headers[header::ETAG].clone();
        let etag = etag.to_str().unwrap();
        assert_eq!(etag.len(), 66, "{etag}");
        assert_eq!(get(&s, uri, None).await.headers[header::ETAG], etag);
        for cached in [etag.to_string(), format!("W/{etag}")] {
            let r = revalidate(uri, &cached).await;
            assert_eq!(
                (r.status, r.body, r.headers[header::ETAG].to_str().unwrap()),
                (StatusCode::NOT_MODIFIED, vec![], etag),
                "{uri} {cached}"
            );
        }
        let r = revalidate(uri, "\"stale\"").await;
        assert_eq!(r.status, StatusCode::OK);
        assert!(!r.body.is_empty());
    }
    let css = get(&s, "/static/css/main.css", None).await;
    let favicon = get(&s, "/static/favicons/xott.png", None).await;
    assert_ne!(css.headers[header::ETAG], favicon.headers[header::ETAG]);
}

#[tokio::test]
async fn protected_without_session() {
    let s = site();
    for uri in [
        "/photo",
        "/photo/misc",
        "/photo/misc/zip",
        "/photo/fullsize/misc/a.jpg",
        "/photo/preview/misc/a.jpg",
    ] {
        let r = get(&s, uri, None).await;
        assert_eq!(
            (r.status, r.text()),
            (
                StatusCode::UNAUTHORIZED,
                pages::login(uri, false).into_string()
            ),
            "{uri}"
        );
    }
    insta::assert_yaml_snapshot!(get(&s, "/photo/misc", None).await.snap(), @r#"
    status: 401
    headers:
      cache-control: no-store
      content-length: "641"
      content-type: text/html; charset=utf-8
    body:
      - "<div id=\"login\">"
      - "<form class=\"pill\" id=\"auth\" method=\"post\" action=\"/login\">"
      - "<input type=\"hidden\" name=\"next\" value=\"/photo/misc\">"
      - "<input class=\"pill\" type=\"password\" name=\"password\" placeholder=\"password\" required autofocus>"
      - "<button class=\"pill\" type=\"submit\">login</button>"
      - "</form>"
      - "</div>"
    "#);
}

#[tokio::test]
async fn cache_control() {
    let s = site();
    let c = session(&s).await;
    let policy = |r: &Res| {
        r.headers[header::CACHE_CONTROL]
            .to_str()
            .unwrap()
            .to_string()
    };
    for (uri, cookie, expected) in [
        ("/photo", Some(&c), "no-store"),
        ("/photo/misc", Some(&c), "no-store"),
        ("/photo/misc", None, "no-store"),
        ("/photo/preview/misc/a.jpg", None, "no-store"),
        ("/photo/preview/misc/a.jpg", Some(&c), "no-cache"),
        ("/photo/fullsize/misc/a.jpg", Some(&c), "no-cache"),
    ] {
        assert_eq!(
            policy(&get(&s, uri, cookie.map(String::as_str)).await),
            expected,
            "{uri}"
        );
    }
    assert!(
        !get(&s, "/", None)
            .await
            .headers
            .contains_key(header::CACHE_CONTROL)
    );
}

// revalidation is cheap with a session, and fails without one
#[tokio::test]
async fn image_revalidation() {
    let s = site();
    let c = session(&s).await;
    let uri = "/photo/preview/misc/a.jpg";
    let first = get(&s, uri, Some(&c)).await;
    let modified = first.headers[header::LAST_MODIFIED].clone();
    let revalidate = |cookie: Option<&str>| {
        let mut req = Request::get(uri).header(header::IF_MODIFIED_SINCE, modified.clone());
        if let Some(c) = cookie {
            req = req.header(header::COOKIE, c);
        }
        send(&s, req.body(Body::empty()).unwrap())
    };
    let cached = revalidate(Some(&c)).await;
    assert_eq!(
        (
            cached.status,
            cached.headers[header::CACHE_CONTROL].to_str().unwrap()
        ),
        (StatusCode::NOT_MODIFIED, "no-cache")
    );
    assert_eq!(revalidate(None).await.status, StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn wrong_password() {
    let s = site();
    insta::assert_yaml_snapshot!(login(&s, "nope", "/photo/misc").await.snap(), @r#"
    status: 401
    headers:
      content-length: "681"
      content-type: text/html; charset=utf-8
    body:
      - "<div id=\"login\">"
      - "<div class=\"pill\" id=\"error\">wrong</div>"
      - "<form class=\"pill\" id=\"auth\" method=\"post\" action=\"/login\">"
      - "<input type=\"hidden\" name=\"next\" value=\"/photo/misc\">"
      - "<input class=\"pill\" type=\"password\" name=\"password\" placeholder=\"password\" required autofocus>"
      - "<button class=\"pill\" type=\"submit\">login</button>"
      - "</form>"
      - "</div>"
    "#);
}

#[tokio::test]
async fn login_redirects_back() {
    let s = site();
    insta::assert_yaml_snapshot!(
        login(&s, PASS, "/photo/misc").await.snap(),
        { ".headers[\"set-cookie\"]" => redact_cookie() },
        @r#"
    status: 303
    headers:
      content-length: "0"
      location: /photo/misc
      set-cookie: "session=[value]; HttpOnly; SameSite=Lax; Secure; Path=/; Max-Age=3600"
    body: []
    "#
    );
}

#[tokio::test]
async fn album_list() {
    let s = site();
    let c = session(&s).await;
    insta::assert_yaml_snapshot!(get(&s, "/photo", Some(&c)).await.snap(), @r#"
    status: 200
    headers:
      cache-control: no-store
      content-length: "726"
      content-type: text/html; charset=utf-8
    body:
      - "<a href=\"/\">ctrl.sn</a> <span class=\"sep\">•</span> photo <span class=\"sep\">•</span> <form class=\"inline\" method=\"post\" action=\"/logout\">"
      - "<button class=\"link\">logout</button>"
      - "</form>"
      - "<ul>"
      - "<li>"
      - "<a href=\"/photo/misc\">misc</a>"
      - "</li>"
      - "<li>"
      - "<a href=\"/photo/2025-01-02_paris\">2025-01-02_paris</a>"
      - "</li>"
      - "<li>"
      - "<a href=\"/photo/2024-05-01_berlin\">2024-05-01_berlin</a>"
      - "</li>"
      - "</ul>"
    "#);
}

#[tokio::test]
async fn album_page() {
    let s = site();
    let c = session(&s).await;
    insta::assert_yaml_snapshot!(get(&s, "/photo/misc", Some(&c)).await.snap(), @r#"
    status: 200
    headers:
      cache-control: no-store
      content-length: "1163"
      content-type: text/html; charset=utf-8
    body:
      - "<a href=\"/\">ctrl.sn</a> <span class=\"sep\">•</span> <a href=\"/photo\">photo</a> <span class=\"sep\">•</span> misc <span class=\"sep\">•</span> <a href=\"/photo/misc/zip\">zip</a>"
      - "<div id=\"album\">"
      - "<a href=\"/photo/fullsize/misc/a.jpg\" data-fslightbox=\"gallery\">"
      - "<img src=\"/photo/preview/misc/a.jpg\" loading=\"lazy\" onerror=\"this.onerror=null; this.src='/static/assets/pfp.gif';\">"
      - "</a>"
      - "<a href=\"/photo/fullsize/misc/b.jpg\" data-fslightbox=\"gallery\">"
      - "<img src=\"/photo/preview/misc/b.jpg\" loading=\"lazy\" onerror=\"this.onerror=null; this.src='/static/assets/pfp.gif';\">"
      - "</a>"
      - "<a href=\"/photo/fullsize/misc/ü.jpg\" data-fslightbox=\"gallery\">"
      - "<img src=\"/photo/preview/misc/ü.jpg\" loading=\"lazy\" onerror=\"this.onerror=null; this.src='/static/assets/pfp.gif';\">"
      - "</a>"
      - "</div>"
      - "<script src=\"/static/js/fslightbox.js\">"
      - "</script>"
    "#);
}

#[tokio::test]
async fn missing_and_traversal() {
    let s = site();
    let c = session(&s).await;
    let uris = [
        "/photo/nope",
        "/photo/nope/zip",
        "/photo/..",
        "/photo/..%2F..%2Fetc",
        "/photo/..%2Ffullsize/zip",
        "/photo/fullsize/..%2F..%2Fetc%2Fpasswd",
        "/photo/fullsize/misc/nope.jpg",
    ];
    let mut got = vec![];
    for uri in uris {
        got.push((uri, get(&s, uri, Some(&c)).await.status));
    }
    assert_eq!(got, uris.map(|u| (u, StatusCode::NOT_FOUND)));
}

#[tokio::test]
async fn not_found_page() {
    let s = site();
    let c = session(&s).await;
    let page = pages::not_found().into_string();
    let uris = [
        "/nope",
        "/static/nope.css",
        "/photo/nope",
        "/photo/fullsize/misc/nope.jpg",
    ];
    let mut got = vec![];
    for uri in uris {
        let r = get(&s, uri, Some(&c)).await;
        got.push((uri, r.status, r.text()));
    }
    assert_eq!(got, uris.map(|u| (u, StatusCode::NOT_FOUND, page.clone())));
    insta::assert_yaml_snapshot!(get(&s, "/nope", None).await.snap(), @r#"
    status: 404
    headers:
      content-length: "421"
      content-type: text/html; charset=utf-8
    body:
      - "<a href=\"/\">ctrl.sn</a> <span class=\"sep\">•</span> 404"
    "#);
}

#[tokio::test]
async fn images() {
    let s = site();
    let c = session(&s).await;
    let mut got = vec![];
    for uri in [
        "/photo/fullsize/misc/a.jpg",
        "/photo/preview/2024-05-01_berlin/x.jpg",
    ] {
        let r = get(&s, uri, Some(&c)).await;
        got.push((r.status, r.text()));
    }
    assert_eq!(
        got,
        [
            (StatusCode::OK, "fullsize a.jpg".into()),
            (StatusCode::OK, "preview x.jpg".into())
        ]
    );
}

#[tokio::test]
async fn zip() {
    let s = site();
    let r = get(&s, "/photo/misc/zip", Some(&session(&s).await)).await;
    assert_eq!(r.headers[header::CONTENT_LENGTH], r.body.len().to_string());
    let mut zip = zip::ZipArchive::new(std::io::Cursor::new(&r.body)).unwrap();
    let mut files = BTreeMap::new();
    for i in 0..zip.len() {
        let mut f = zip.by_index(i).unwrap();
        let mut data = String::new();
        f.read_to_string(&mut data).unwrap();
        files.insert(f.name().unwrap().to_string(), data);
    }
    insta::assert_yaml_snapshot!((r.status.as_u16(), r.header_map(), files), @r#"
    - 200
    - cache-control: no-cache
      content-disposition: "attachment; filename=\"misc.zip\""
      content-length: "325"
      content-type: application/zip
    - a.jpg: fullsize a.jpg
      b.jpg: fullsize b.jpg
      ü.jpg: fullsize ü.jpg
    "#);
}

#[tokio::test]
async fn bad_sessions() {
    let s = site();
    let other = site();
    let mut got = vec![];
    for c in [
        "session=9999999999".to_string(),
        signed(&s, "0"),
        signed(&s, "garbage"),
        session(&other).await,
        signed(&s, "9999999999"),
    ] {
        got.push(get(&s, "/photo", Some(&c)).await.status);
    }
    assert_eq!(
        got,
        [
            StatusCode::UNAUTHORIZED,
            StatusCode::UNAUTHORIZED,
            StatusCode::UNAUTHORIZED,
            StatusCode::UNAUTHORIZED,
            StatusCode::OK
        ]
    );
}

#[tokio::test]
async fn logout() {
    let s = site();
    let req = Request::post("/logout").header(header::COOKIE, session(&s).await);
    let r = send(&s, req.body(Body::empty()).unwrap()).await;
    insta::assert_yaml_snapshot!(
        r.snap(),
        { ".headers[\"set-cookie\"]" => redact_cookie() },
        @r#"
    status: 303
    headers:
      content-length: "0"
      location: /
      set-cookie: "session=; Path=/; Max-Age=0; Expires=[date]"
    body: []
    "#
    );
}

#[tokio::test]
async fn trailing_slash() {
    let s = site();
    let mut got = BTreeMap::new();
    for uri in [
        "/photo/",
        "/photo/misc//?a=1",
        "//evil.com/",
        "/\\evil.com/",
        "/nope",
    ] {
        let r = get(&s, uri, None).await;
        let loc = r
            .headers
            .get(header::LOCATION)
            .map(|v| v.to_str().unwrap().to_string());
        got.insert(uri, (r.status.as_u16(), loc));
    }
    insta::assert_yaml_snapshot!(got, @r#"
    //evil.com/:
      - 308
      - /evil.com
    "/\\evil.com/":
      - 308
      - /evil.com
    /nope:
      - 404
      - ~
    /photo/:
      - 308
      - /photo
    /photo/misc//?a=1:
      - 308
      - /photo/misc?a=1
    "#);
}

#[tokio::test]
async fn titles() {
    let s = site();
    let c = session(&s).await;
    let title = |r: Res| {
        let t = r.text();
        t.split_once("<title>")
            .unwrap()
            .1
            .split_once("</title>")
            .unwrap()
            .0
            .to_string()
    };
    let mut got = BTreeMap::new();
    for uri in ["/", "/about", "/photo", "/photo/misc", "/nope"] {
        got.insert(uri, title(get(&s, uri, Some(&c)).await));
    }
    got.insert("login", title(get(&s, "/photo", None).await));
    insta::assert_yaml_snapshot!(got, @"
    /: ctrl.sn
    /about: ctrl.sn • about
    /nope: ctrl.sn • 404
    /photo: ctrl.sn • photo
    /photo/misc: ctrl.sn • misc
    login: ctrl.sn
    ");
}
