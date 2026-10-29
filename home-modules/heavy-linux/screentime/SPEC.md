# screentime: AI-based screen time tracker

Records how time on f12's screen is spent, as `(start, end, class)` spans.
Classification is done by bgm5's decision model
(`consts.llama.host:decisionPort`, `/v1/systemone`).

There are two trackers. Neither makes network calls besides the model:

- The **screen tracker** runs on f12. It follows niri focus and classifies
  non-terminal windows. For a terminal running zellij it only records which
  pane was on screen, as `(host, session, pane_id)`, parsed from the window
  title.
- The **zellij tracker** runs on every `heavy-linux` host (f12, bgm5). It logs a
  class timeline for each zellij pane that some client has focused.

A report merges the two: every screen-tracker pane span is replaced by the
pane's classes over that interval, pulled from the host that ran the
session. Time in zellij on other hosts (e.g. anuramat-root) is reported as
`unknown`.

Both trackers are SLOP: AI-owned black boxes with comprehensive tests.

## Placement

- `home-modules/heavy-linux/screentime/`: both trackers and the report CLI,
  in Python (PIL, sqlite3).
  - `screentime.service`: the screen tracker, `PartOf`/`After`
    `niri.service`, enabled on f12 only.
  - `screentime-zellij.service`: the zellij tracker, enabled on every host
    with `heavy-linux`.
  - `screentime report`: the report, on f12.
  - The classes, the dir map and the app map are one Nix attrset in the
    module, rendered to a JSON config that both trackers read.
  - Tests: pytest in the package's `checkPhase`, with recorded niri and
    zellij output as fixtures.
- ghostty patch and config: `home-modules/heavy-linux/gui/terminals.nix`.
- zellij patch: the existing `zellij-unwrapped` override in
  `overlays/default.nix`.
- noctalia lock hooks: `home-modules/heavy-linux/desktop/noctalia/default.nix`.

## Classes

There is one dimension: `class`. Project classes are ordinary classes next
to generic ones. The criteria text given to the model is the only definition
of a class, so the same definition applies to terminals, browser tabs and
any other window. The classes and criteria are shared by both trackers.

| class | criteria |
|---|---|
| nixos | NixOS and nix: the NixOS configuration, nix code, NixOS wiki and docs, nix forums |
| thesis | research related to diffusion models: papers, notes, experiments |
| vicode | stuff relevant to writing a coding agent in Rust |
| coding | programming, debugging or terminal work not covered by a project class |
| photography | editing in darktable, photography books, videos, articles |
| chat | Telegram, Discord |
| tech | reading on science, tech or software, e.g. in the web browser |
| web | web browsing not covered by the classes above |
| misc | everything else |

The question's `instructions` tell the model to pick the most specific
class: the project classes (nixos, thesis, vicode) first, then coding,
photography and chat, then tech, then web, and misc last.

Two classes are added by the trackers and are never model options:
`locked` and `unknown`, the latter for screen time that no pane timeline
covers.

The dir map is a shortcut for the zellij tracker: `path -> class`, matched
on the longest prefix of a pane's cwd, on every host. A match sets the class
without a model call.

| path | class |
|---|---|
| `/etc/nixos` | nixos |
| `~/.local/share/ghq/github.com/anuramat/diffusion` | thesis |
| `~/.local/share/ghq/github.com/anuramat/vicode` | vicode |

The app map is the same kind of shortcut for the screen tracker: niri
`app_id -> class`, checked before any other target rule.

| app_id | class |
|---|---|
| `org.telegram.desktop` | chat |
| `discord` | chat |
| `org.darktable.darktable` | photography |

## Titles

zellij patch: `make_terminal_title` (`zellij-utils/src/shared.rs`) takes the
pane id from its callers (`render_terminal_title` in
`panes/terminal_pane.rs` and `panes/plugin_pane.rs`, via `self.pid`) and
writes `<hostname>/<session>/<pane_id>`, without the pane title. `pane_id`
is `terminal_N` or `plugin_N`, the format that `dump-screen -p` takes. A
second patch keeps the title last sent per client instead of per tab
(`ui/pane_contents_and_ui.rs`), so that a tab switch, or another client in
the same tab, re-sends it.

ghostty: `title = "ghostty"` is dropped, so the window title follows the
program again. A patch prefixes the computed title with `ghostty - `
(`src/apprt/gtk/class/tab.zig`, the `plain` title computation).
`bell-features` is set to the defaults minus `title`, so the bell never adds
a prefix.

So a ghostty window showing zellij is titled, for example,
`ghostty - anuramat-bgm5/adamant-peach/terminal_3`, both locally and over
ssh. zellij writes it for each client from the pane that client has
focused, and programs inside panes can't change it.

## Screen tracker (f12)

Input is `niri msg --json event-stream`:

- `WindowFocusChanged`: exact switch times.
- `WindowOpenedOrChanged`: title changes. A tab or pane switch in zellij
  changes the pane id in the title, so it arrives immediately.
- `WindowClosed`: drops the window's cache entries.

The focused window resolves to a target:

| target | recorded as | classifier input |
|---|---|---|
| `app_id` in the app map | class from the map | none |
| ghostty, title parses as a zellij title | pane span `(host, session, pane_id)` | none |
| other (including firefox and ghostty without zellij) | class | title; if confidence < T, title + screenshot |

For classified targets, the cache key is the normalized title for firefox
(shared across windows, since the same input always gets the same answer),
and `(window_id, normalized title)` for other windows. Normalization strips
leading non-alphanumeric characters (spinners, icons) and a leading `(N)`
counter. A key change is a cache lookup: a miss is classified, and a hit
reuses its class. Rechecks catch content changes under an unchanged key.

Screenshots are of the whole focused output, `grim -o <output>` with the
output from `niri msg --json focused-output`, scaled to fit within
1024x1024. niri's IPC gives no position for tiled windows
(`tile_pos_in_workspace_view` is only set for floating ones), so a window
geometry for `grim -g` isn't available. Not
`niri msg action screenshot-window`, because it always sets the clipboard.

A title-only answer with confidence at least T holds until the title
changes. A recheck always sends title + screenshot, which catches e.g.
single-page apps whose title never changes. The screenshot is taken before
the title-only call, so that it shows what the title names.

While a classification is pending, time goes to the target's previous class
if it has one, or to spans with class `pending` that are updated in place
once the answer arrives. Anything still `pending` at report time counts as
`unknown`. A span starts at the moment of the change, never at the moment
classification finished.

Lock: noctalia's `session_locked` hook runs
`systemctl --user kill --kill-whom=main -s SIGUSR1 screentime` (only the
main process: the niri event stream would die of the signal), and `session_unlocked` runs
the same with `SIGUSR2`. When locked, the tracker closes the current span,
opens a `locked` span and stops capturing. When unlocked, it resolves the
focused window again.

Storage, in `$XDG_STATE_HOME/screentime.db`:

- `spans(start, end, class, pane)`: either `class` is set, or `pane` is
  `host/session/pane_id`. On each tick, the current value extends the last
  row if it is equal and `now - last.end < 2 * tick`. Otherwise a new row is
  inserted. A suspend or a crash therefore leaves a gap instead of a span
  bridging it.
- `classifications(t, target, input_kind, class, confidence)`: a debug and
  calibration log. `target` is the cache key in plain text during
  calibration, and a SHA-256 hash of it afterwards, so window titles aren't
  kept.

## zellij tracker (every heavy-linux host)

Every 2s, locally and with no network (every zellij CLI call runs under
`timeout 5`, so a hung session can't block the loop):

1. `zellij list-sessions -n`, without the `(EXITED ...)` ones (`-s` lists
   them too).
2. For each session: `list-clients` (`CLIENT_ID ZELLIJ_PANE_ID
   RUNNING_COMMAND`, text) gives the set of panes focused by at least one
   client. Which client focuses a pane doesn't matter, because the screen
   tracker identifies panes, not clients.
3. `list-panes -a --json` gives `pane_cwd` and `pane_command` for those
   panes.
4. For each focused terminal pane, the class comes from the dir map, or
   from the cache keyed by `(session, pane_id)`. On a miss or a recheck, it
   classifies `dump-screen -p terminal_N` (viewport only) together with
   `pane_command` and the cwd. Plugin panes aren't classified, so their
   screen time ends up `unknown`.

The tracker can't tell whether anyone is looking at a pane. It classifies
every focused pane, and the report uses only the intervals covered by
screen-tracker spans. With rechecks backing off to 5 minutes, an unwatched
static pane costs about 12 text calls per hour.

Storage, in `$XDG_STATE_HOME/screentime-zellij.db`:
`pane_spans(start, end, session, pane_id, class)`, extended and split with
the same rule as `spans`. There is one open row per focused pane.

## Classification (both trackers)

Requests use the decision-bot form: `state` (text, with `<image:N>`
references), `media` (`[{type: image, data: <jpeg data URI>}]`) and one
`choice` question over the classes. The answer is `choice` and
`confidence` (0 means uniform, 1 means certain).

Rechecks: while a target is focused (a window on f12, a pane in a zellij
session), it is reclassified after its cache entry's `recheck_after`
interval, which starts at 30s. The interval doubles each time a recheck
returns the same class, up to 5 minutes, and resets to 30s when the class
changes.

Rate cap: each tracker has a token bucket. The screen tracker gets 4
image-call equivalents per minute (burst 2), where text-only calls cost a
fraction of a token, measured from latency. The zellij tracker gets 6 text
calls per minute. When a classification is due without a token, the target is
marked dirty, and only its newest input is classified once a token is
available.

Failures: if the model is unreachable or returns an error, the time is
recorded as `unknown`, and the target is retried at its next recheck. No
backfill, since the content may have changed by then.

Screenshots, terminal text and prompts are never stored or logged.

## Report

`screentime report [--since WHEN]` on f12, where `WHEN` defaults to 7 days
ago:

1. Read `spans` from the local database.
2. For each host that appears in a `pane` value, read that host's
   `pane_spans` over the same range: directly for f12, and with
   `ssh -o BatchMode=yes <host> screentime zellij-log SINCE` (JSON, with the
   times of the tracker's model calls) for the others. This host's zellij
   tracker is always read, for its calls.
3. Replace each pane span with the intersection of its interval and that
   pane's `pane_spans`. Parts no pane span covers become `unknown`.
4. Print a table with one row per day, one column per class, and a column
   with the number of answered model calls of the trackers read.

If a host can't be reached, its pane spans are reported as `unknown`, and a
warning names the host. Hosts are assumed to be NTP-synced, and title-event
lag only blurs span edges by a fraction of a second.

## Calibration (first rollout)

For a day, the screen tracker logs both the title-only answer and the
title + screenshot answer for every first classification. T is then set
to the lowest value at which a confident title-only answer almost never
disagrees with the full answer. The classification logs of both trackers
show how often rechecks change the class, which is the basis for tuning
the recheck intervals.

## To verify during implementation

- Patched titles after a tab switch, locally and over ssh.
