use crate::{AppState, pages};
use axum::{
    Form,
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Redirect, Response},
};
use axum_extra::extract::{
    SignedCookieJar,
    cookie::{Cookie, SameSite},
};
use serde::Deserialize;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const COOKIE: &str = "session";
const TTL: Duration = Duration::from_hours(1);

fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs()
}

// the signed cookie holds the expiry timestamp
pub async fn require(jar: SignedCookieJar, req: Request, next: Next) -> Response {
    let expiry = jar.get(COOKIE).and_then(|c| c.value().parse::<u64>().ok());
    if expiry.is_some_and(|t| t > now()) {
        return next.run(req).await;
    }
    (
        StatusCode::UNAUTHORIZED,
        pages::login(req.uri().path(), false),
    )
        .into_response()
}

#[derive(Deserialize)]
pub struct Login {
    password: String,
    // page to return to
    next: String,
}

pub async fn login(
    State(s): State<AppState>,
    jar: SignedCookieJar,
    Form(f): Form<Login>,
) -> Response {
    if f.password != s.pass {
        return (StatusCode::UNAUTHORIZED, pages::login(&f.next, true)).into_response();
    }
    let cookie = Cookie::build((COOKIE, (now() + TTL.as_secs()).to_string()))
        .path("/")
        .http_only(true)
        .secure(true)
        .same_site(SameSite::Lax)
        .max_age(TTL.try_into().unwrap());
    (jar.add(cookie), Redirect::to(&f.next)).into_response()
}

pub async fn logout(jar: SignedCookieJar) -> impl IntoResponse {
    (
        jar.remove(Cookie::build(COOKIE).path("/")),
        Redirect::to("/"),
    )
}
