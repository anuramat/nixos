// the cookie is HttpOnly, so ask the server; the login page doesn't load this
// script, so the reload can't loop
const checkSession = () =>
  fetch(location.href, { method: "HEAD" }).then(
    (r) => r.status == 401 && location.reload(),
  );

addEventListener("pageshow", (e) => e.persisted && checkSession());
document.addEventListener(
  "visibilitychange",
  () => document.hidden || checkSession(),
);
