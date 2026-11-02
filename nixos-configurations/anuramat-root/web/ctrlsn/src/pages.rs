use maud::{DOCTYPE, Markup, html};

pub fn sep() -> Markup {
    html! { " " span.sep { "\u{2022}" } " " }
}

pub fn page(body: &Markup) -> Markup {
    html! {
        (DOCTYPE)
        html lang="en" {
            head {
                meta charset="utf-8";
                meta name="viewport" content="width=device-width, initial-scale=1";
                link rel="icon" type="image/png" href="/static/favicons/xott.png";
                link rel="stylesheet" href="/static/css/modern-normalize.css";
                link rel="stylesheet" href="/static/css/main.css";
                title { "ctrl.sn" }
            }
            body { (body) }
        }
    }
}

// links to every ancestor of the page at /path[0]/path[1]/...
pub fn crumbs(path: &[&str]) -> Markup {
    let mut all = vec![("/".to_string(), "ctrl.sn")];
    for s in path {
        all.push((
            format!("{}/{s}", all.last().unwrap().0.trim_end_matches('/')),
            *s,
        ));
    }
    let ((_, name), parents) = all.split_last().unwrap();
    html! {
        @for (href, n) in parents {
            a href=(href) { (n) }
            (sep())
        }
        (name)
    }
}

pub async fn index() -> Markup {
    page(&html! {
        (crumbs(&[]))
        ul {
            li { a href="/about" { "about" } }
            li { a href="/photo" { "photo" } }
        }
        p { "last updated: 2026-10-30" }
    })
}

pub async fn about() -> Markup {
    page(&html! {
        (crumbs(&["about"]))
        br;
        img #pfp src="/static/assets/pfp.gif";
        ul {
            li { a href="mailto:x@ctrl.sn" { "email" } }
            li { a href="https://t.me/anuramat" { "tg" } }
            li { a href="https://github.com/anuramat" { "github" } }
            li { a href="https://instagram.com/anuramat" { "ig" } }
        }
    })
}

pub fn not_found() -> Markup {
    page(&html! { (crumbs(&["404"])) })
}

pub fn login(next: &str, wrong: bool) -> Markup {
    page(&html! {
        #login {
            @if wrong { #error .pill { "wrong" } }
            form #auth .pill method="post" action="/login" {
                input type="hidden" name="next" value=(next);
                input .pill type="password" name="password" placeholder="password" required autofocus;
                button .pill type="submit" { "login" }
            }
        }
    })
}
