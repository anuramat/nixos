mod auth;
mod pages;
mod photo;
mod tests;

use axum::{
    Router,
    extract::{FromRef, Path},
    http::{
        HeaderMap, StatusCode, Uri,
        header::{CONTENT_TYPE, ETAG, IF_NONE_MATCH},
    },
    middleware,
    response::{IntoResponse, Redirect, Response},
    routing::{get, post},
};
use axum_extra::extract::cookie::Key;
use rust_embed::RustEmbed;
use std::{env, fmt::Write, path::PathBuf};
use tower_http::services::ServeDir;

#[derive(Clone)]
struct AppState {
    key: Key,
    pass: String,
    // contains fullsize/ and preview/, each with a subdirectory per album
    photos: PathBuf,
}

impl FromRef<AppState> for Key {
    fn from_ref(s: &AppState) -> Self {
        s.key.clone()
    }
}

#[derive(RustEmbed)]
#[folder = "static"]
struct Static;

// third-party assets from the flake inputs
#[derive(RustEmbed)]
#[folder = "$CTRLSN_VENDOR"]
struct Vendor;

// revalidated with a content hash: nix builds set every mtime to 1970, so
// Last-Modified would never change
async fn asset(Path(path): Path<String>, headers: HeaderMap) -> Response {
    let Some(f) = Static::get(&path).or_else(|| Vendor::get(&path)) else {
        return StatusCode::NOT_FOUND.into_response();
    };
    let hash = f
        .metadata
        .sha256_hash()
        .iter()
        .fold(String::new(), |mut s, b| {
            write!(s, "{b:02x}").unwrap();
            s
        });
    let etag = format!("\"{hash}\"");
    let cached = headers.get(IF_NONE_MATCH).and_then(|v| v.to_str().ok());
    if cached.is_some_and(|v| v.trim_start_matches("W/") == etag) {
        return (StatusCode::NOT_MODIFIED, [(ETAG, etag)]).into_response();
    }
    let mime = f.metadata.mimetype().to_owned();
    ([(CONTENT_TYPE, mime), (ETAG, etag)], f.data).into_response()
}

// `/photo/` -> `/photo`; leading slashes are collapsed too, so that `//host/`
// can't become a protocol-relative redirect
async fn trailing_slash(uri: Uri) -> Response {
    if !uri.path().ends_with('/') {
        return StatusCode::NOT_FOUND.into_response();
    }
    let path = uri.path().trim_matches(['/', '\\']);
    let query = uri.query().map_or_else(String::new, |q| format!("?{q}"));
    Redirect::permanent(&format!("/{path}{query}")).into_response()
}

// every 404 gets the same page, whichever handler or service returned it
async fn not_found(r: Response) -> Response {
    if r.status() == StatusCode::NOT_FOUND {
        (StatusCode::NOT_FOUND, pages::not_found()).into_response()
    } else {
        r
    }
}

fn app(state: AppState) -> Router {
    Router::new()
        .route("/photo", get(photo::albums))
        .route("/photo/{album}", get(photo::album))
        .route("/photo/{album}/zip", get(photo::zip))
        .nest_service(
            "/photo/fullsize",
            ServeDir::new(state.photos.join("fullsize")),
        )
        .nest_service(
            "/photo/preview",
            ServeDir::new(state.photos.join("preview")),
        )
        // only applies to the routes above
        .route_layer(middleware::from_fn_with_state(state.clone(), auth::require))
        .route("/", get(pages::index))
        .route("/about", get(pages::about))
        .route("/static/{*path}", get(asset))
        .route("/login", post(auth::login))
        .route("/logout", post(auth::logout))
        .fallback(trailing_slash)
        .layer(middleware::map_response(not_found))
        .with_state(state)
}

#[tokio::main]
async fn main() {
    let var = |k| env::var(k).unwrap_or_else(|_| panic!("{k} is not set"));
    let state = AppState {
        // sessions don't survive restarts
        key: Key::generate(),
        pass: var("PHOTO_PASS"),
        photos: var("PHOTO_DIR").into(),
    };
    let listener = tokio::net::TcpListener::bind(format!("127.0.0.1:{}", var("PORT")))
        .await
        .unwrap();
    axum::serve(listener, app(state)).await.unwrap();
}
