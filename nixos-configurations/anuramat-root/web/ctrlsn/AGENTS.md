# ctrl.sn

My personal website: photo galleries behind a password; blog posts are
planned.

## Stack

Rust: axum + tokio, maud for HTML, rust-embed for `static/` (embedded in
release builds, read from disk in debug builds), axum-extra signed cookies
for auth, async_zip for album downloads. Built with
crane in `default.nix` (dependencies are a separate derivation), imported by
`index.nix` next to this directory with the `/etc/nixos` flake's inputs.
Standalone, `default.nix` and `shell.nix` take nixpkgs, crane and the assets
from `NIX_PATH`, which NixOS points at the same inputs; new inputs show up
there only after a rebuild.

Third-party assets (fslightbox, modern-normalize) are inputs of the
`/etc/nixos` flake (npm tarballs), copied into `$CTRLSN_VENDOR` by `default.nix` and embedded like
`static/`; both are served under `/static`. To update one, change its URL in
`/etc/nixos/flake.nix`.

## Layout

```
src/main.rs    state, router, embedded static files, entry point
src/auth.rs    login/logout, session middleware
src/pages.rs   layout, breadcrumbs, public pages, login page
src/photo.rs   album listing/sorting, album page, zip download
src/tests.rs   in-process router tests
static/        css, images
```

## Behaviour

- `/`, `/about`, `/static/*` are public.
- `/photo`, `/photo/{album}`, `/photo/{album}/zip`, `/photo/fullsize/*`,
  `/photo/preview/*` require a session; otherwise the login page is
  returned with 401. The login form posts to `/login` with the page to
  return to; `/logout` is a POST. Their HTML responses are `no-store` and
  the rest `no-cache`, so that browsers can't show them without a session.
- Any other path ending in `/` redirects (308) to the same path without
  the trailing slashes, keeping the query; the rest is 404.
- Every 404, from any handler or `ServeDir`, gets the same page.
- Single password, no username. The session cookie is signed with
  `SESSION_KEY` (changing it logs everyone out; changing the password
  doesn't) and holds its expiry (30 days).
- `static/js/session.js` reloads the album pages into the login page when
  the session is gone: on back/forward restores, when the tab is shown
  again, and when a preview fails to load.
- Albums are the subdirectories of `$PHOTO_DIR/fullsize`, read on every
  request, in reverse alphabetical order: names start with `YYYY-MM-DD_`,
  so the newest album comes first. Previews (256px) live under the same paths in `$PHOTO_DIR/preview`.

## Configuration

Environment variables, all required: `PORT` (binds 127.0.0.1),
`PHOTO_DIR`, `PHOTO_PASS`, `SESSION_KEY` (at least 64 bytes:
`openssl rand -hex 32`).

## Commands

- `nix-shell`: shell with cargo, clippy, rust-analyzer,
  cargo-insta;
  cargo only builds inside it, since it needs `$CTRLSN_VENDOR`
- `PORT=8080 PHOTO_DIR=path/to/photos PHOTO_PASS=dev SESSION_KEY=$(openssl rand -hex 32) cargo run`: run locally
- `cargo test`, `cargo clippy --all-targets`
- `nix-build` (also runs the tests); `nix fmt` in `/etc/nixos` formats
  everything, including rustfmt

Before committing: `nix-build` succeeds and `nix fmt` changes
nothing.

## Deployment

NixOS host `anuramat-root`, configured in `/etc/nixos`
(`index.nix` next to this directory): nginx terminates TLS and proxies to
the `ctrl.sn` systemd service (`DynamicUser`), `PHOTO_PASS` and `SESSION_KEY` come from the
agenix secret `ctrlsn.age`, photos are uploaded to `/var/www/photo`; then
`make` in `/var/www` (`previews.mk` next to this directory) generates the
missing previews. To deploy: rebuild `anuramat-root`.
