# TODO

Refactoring opportunities and straightforward TODOs, from an audit of the repo at commit 9d347469 (2026-10-09). Each item was reported by an auditor and then checked against the code by an independent verifier; line numbers refer to that commit.

Items are numbered per section (A1, B3, ...). Sections A-G are confirmed and need no decision from you; section H collects everything that does; section I lists proposals that were rejected.

- A. Bugs and broken tooling
- B. Dead code and leftovers
- C. Options set to their defaults, duplicated or deprecated
- D. TODOs that can be resolved now
- E. Stale docs
- F. Refactors: flake, NixOS, Home Manager
- G. Refactors: nixvim
- H. Needs your decision
- I. Considered and rejected

## A. Bugs and broken tooling

### A1. gh: `extensions` is nested under `settings`, so gh-f is never installed

**Where:** `home-modules/base/git/gh.nix:10`, `home-modules/base/git/gh.nix:14`
**Effort:** trivial -- **Risk:** low

**Problem:** `programs.gh.settings` contains `extensions = with pkgs; [ gh-f ];` and `prompt = true;`. Home Manager's option is the top-level `programs.gh.extensions` (HM `modules/programs/gh.nix:139`), and only that option feeds `xdg.dataFile."gh/extensions"` (a linkFarm of each package's `bin`). Evaluating f12 gives `programs.gh.extensions = []`, while `settings` serializes `"extensions":["/nix/store/...-gh-f-1.9.0"]` and `"prompt":true` into `config.yml`, where gh ignores the former. `~/.local/share/gh/extensions` does not exist. gh only compares `prompt` against `"disabled"` (HM's own example is `prompt = "enabled"`), so `prompt: true` behaves like the default and the line changes nothing. gh-f supports all platforms, so it is fine in the Darwin-clean base layer.

**Fix:**
- Remove lines 10-12 (`extensions = with pkgs; [ gh-f ];`) and line 14 (`prompt = true;`) from `settings`.
- Add `extensions = [ pkgs.gh-f ];` directly under `programs.gh`, as a sibling of `settings`.

**Verify:** `nix eval --json .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.programs.gh.extensions` lists gh-f, and `...programs.gh.settings` has no `extensions` or `prompt` key. After a switch, `gh f --help` works.

### A2. bin scripts crash under writeShellApplication's nounset (`collect FILE` always fails)

**Where:** `home-modules/base/bin/collect.sh:3`, `home-modules/base/bin/collect.sh:10`, `home-modules/base/bin/parent.sh:3`, `home-modules/base/bin/parent.sh:4`, `home-modules/base/bin/rs.sh:7`
**Effort:** trivial -- **Risk:** none

**Problem:** `bin/default.nix` wraps every `*.sh` with `writeShellApplication`, whose default `bashOptions` are `errexit nounset pipefail` (nixpkgs `trivial-builders/default.nix:271`). Reproduced with the installed binaries:
- `collect.sh:10` reads `[[ -n $2 ]]`, so the documented one-argument usage dies: `collect x.txt` -> `line 17: $2: unbound variable`. The usage guard after `filename="$1"` (line 3) is unreachable for the same reason.
- `parent.sh:3` `pid=$1`: `parent` with no args dies with `$1: unbound variable`. Its usage line is broken too: `echo "usage: $0 $pid"` prints the empty `$pid` and does not exit.
- `rs.sh:7` `host=$1 && shift`: `rs` with no args dies with `$1: unbound variable` instead of printing `$usage`. Switching to `${1-}` alone is not enough: `shift` with no args fails as the last command of the `&&` list, so errexit still kills the script silently, and `realpath -- ""` fails as well. The arity check has to come first.

`tgfy.sh` in the same directory already uses the correct idiom, `${1-}`.

**Fix:**
- `collect.sh`: line 3 `filename="${1-}"`; line 10 `[[ -n ${2-} ]] && dir=...`.
- `parent.sh`: `pid=${1-}` and `[[ -z $pid ]] && { echo "usage: $0 <pid>" >&2; exit 1; }`.
- `rs.sh`: make the first line of `rs()` `[ $# -ge 3 ] || { echo "$usage"; return 1; }` (host, direction and path are required, options may be empty), and leave `host=$1 && shift` etc. as they are.

**Verify:** After a rebuild, `echo hi >x.txt && collect x.txt` prints `hi`; `parent` prints `usage: parent <pid>` and exits 1; `rs` prints the usage and exits 1. `just lint` (shellcheck) stays clean.

### A3. gcreate: the visibility check matches `$2`, so `gcreate NAME` always aborts

**Where:** `home-modules/base/bash/git.sh:164`, `home-modules/base/bash/git.sh:165`, `home-modules/base/bash/git.sh:166`, `home-modules/base/bash/git.sh:167`
**Effort:** trivial -- **Risk:** none

**Problem:** `visibility=private; [ "$2" != "" ] && visibility=$2; case "$2" in private | public) ;; *) return 1 ;; esac`. The case matches `$2` rather than `$visibility`, so with no second argument it falls through to `return 1` before ghq runs, contradicting the documented `$2? - public|private` default. Reproduced: `bash -c 'source home-modules/base/bash/git.sh; ghq(){ echo called >&2; return 1; }; gcreate foo'` returns 1 without calling ghq, while `gcreate foo public` reaches it. `name`, `visibility` and `path` are also assigned without `local`, so they leak into the interactive shell (git.sh is sourced from `bashrcExtra`, `bashrc.nix:50`; cf. the `# TODO more local/readonly` at the top of git.sh).

**Fix:** Replace lines 164-170 with:

```bash
local -r name=$1 visibility=${2:-private}
local path
case "$visibility" in
  private | public) ;;
  *) return 1 ;;
esac
```

Keep `path=$(ghq create "$name") || return 1` as a separate assignment so the exit status is preserved.

**Verify:** The stubbed-ghq command above prints `called` for `gcreate foo`; `gcreate foo bogus` still returns 1 without calling it. shellcheck stays clean.

### A4. gwt: `exit 1` kills the interactive shell; `gwt rm` deletes the wrong path

**Where:** `home-modules/base/bash/git.sh:196`, `home-modules/base/bash/git.sh:199`, `home-modules/base/bash/git.sh:212`, `home-modules/base/bash/git.sh:213`, `home-modules/base/bash/git.sh:216`, `home-modules/base/bash/bashrc.sh:4`
**Effort:** small -- **Risk:** low

**Problem:**
- git.sh is sourced into interactive bash (`bashrc.nix:50`), so `*) exit 1 ;;` (line 216) closes the terminal on any bad subcommand. Reproduced: `gwt bogus x` terminates the shell.
- Line 213 `rm -rf "${worktree:?}/$2"` deletes `<picked worktree>/<query>`. For `gwt rm x` that is `.../worktrees/REPO/x/x`, which normally does not exist, so `rm -rf` silently does nothing. Even with the right path it would leave stale `.git/worktrees` metadata behind.
- The pipeline `git worktree list --porcelain -z | grep -z ... | cut -zd ' ' -f 2` is copied 4 times (gwt x3, gwipe in `bashrc.sh:4`). Line 212 and `bashrc.sh:4` use an unanchored `grep -z worktree`, which also matches records like `branch refs/heads/worktree-foo`, and `cut -f 2` truncates paths that contain spaces.

**Fix:**
- In git.sh, add a helper before gwt: `__worktrees() { git worktree list --porcelain -z | grep -z '^worktree ' | cut -zd ' ' -f 2-; }`.
- Lines 196/199: `cd "$(__worktrees | fzf --read0 ...)" || return` (keeping each line's fzf flags).
- Line 212: `worktree="$(__worktrees | fzf --read0 -q "$name" -1)" || return`.
- Line 213: `gum confirm "delete $worktree" && git worktree remove --force "$worktree"`. `git worktree remove` also refuses to remove the main worktree, which is safer than `rm -rf`; `--force` keeps the original destructive intent, which is already guarded by `gum confirm`.
- Line 216: `return 1`.
- `bashrc.sh:4` (gwipe; bashrc.sh is sourced after git.sh, `bashrc.nix:52`): `__worktrees | grep -vzxF "$PWD" | xargs -0I{} git worktree remove '{}'`.

**Verify:** In a scratch repo: `gwt new x` creates the worktree; `gwt rm x` removes it and `git worktree list` no longer shows it; `gwt bogus x` returns 1 and the shell survives; `gwipe` still removes the other worktrees. shellcheck stays clean.

### A5. gclone: a multi-selection from the picker is iterated as one string

**Where:** `home-modules/base/bash/git.sh:67`, `home-modules/base/bash/git.sh:71`, `home-modules/base/bash/git.sh:77`
**Effort:** trivial -- **Risk:** none

**Problem:** `local repos=$1 ... repos=$(gh repo list | cut -f 1 | __gitgud_picker "") ... for repo in "${repos[@]}"`. `FZF_DEFAULT_OPTS` includes `--multi` (`home-modules/base/search.nix:174`), and `__gitgud_picker` echoes the NL-separated fzf output (git.sh:39-40), so several repos can come back. `repos` is a scalar, though, so the loop runs once with the whole `a<NL>b` string and `gh repo view` fails. The loop over an array expansion shows that multiple repos were intended.

**Fix:** Just before the loop (line 77), add `local -a list; mapfile -t list <<<"$repos"`, and iterate `for repo in "${list[@]}"; do`. Leave everything else unchanged: the trailing `cd "$(basename "${repo%/}")"` uses the last element and runs inside the last owner's directory.

**Verify:** `gclone` with two repos tab-selected clones both; `gclone owner/name` still works; shellcheck stays clean.

### A6. keyring: the linkGpgHome activation reads `$GNUPGHOME` from the environment

**Where:** `home-modules/base/keyring.nix:7`, `home-modules/base/keyring.nix:14`, `home-modules/base/keyring.nix:77`, `home-modules/base/keyring.nix:78`
**Effort:** trivial -- **Risk:** none

**Problem:** Line 7 documents it: `# BUG GNUPGHOME is unset when activating without local nixos module`. The activation runs `ln -sfn "$GNUPGHOME" "$HOME/.gnupg"`, and the HM activation script runs under `set -eu` (`home-environment.nix`, `activationScript`), so an unset GNUPGHOME aborts it. Under NixOS the system unit runs `activate` through a login shell that sources hm-session-vars, which is why it works there; a first standalone `home-manager switch`, or a shell that does not source HM's session vars (e.g. darwin's default), has no GNUPGHOME. The value is known at eval time: HM's gpg module sets `home.sessionVariables.GNUPGHOME = cfg.homedir`, and this file already binds it as `gnupgHome = config.programs.gpg.homedir` (line 14). The line also lacks `run`, so a dry-run activation actually creates the symlink. No other activation reads `$GNUPGHOME`.

**Fix:**
- Line 78: `run ln -sfn ${escapeShellArg gnupgHome} "$HOME/.gnupg"` (`escapeShellArg` is already inherited on line 10).
- Delete the line 7 comment `# BUG GNUPGHOME is unset when activating without local nixos module`, which this fixes; keep the `# WARN getty autologin ...` line. Note for the user: this removes an existing comment.

**Verify:** `nix eval --raw .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.home.activation.linkGpgHome.data` contains `run ln -sfn` with the literal `.../.local/share/gnupg` path and no `$GNUPGHOME`.

### A7. codex: the config.toml activation is hand-rolled and breaks under dry-run

**Where:** `home-modules/heavy-linux/agents/frontends/codex.nix:136`, `home-modules/heavy-linux/agents/frontends/codex.nix:137`, `home-modules/heavy-linux/agents/frontends/codex.nix:30`, `home-modules/base/lib.nix:43`
**Effort:** trivial -- **Risk:** low

**Problem:** `codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] '' run cat ${codexTomlCfg} > "${codexCfgPath}"; '';`. Three issues:
- Under `DRY_RUN`, HM's `run` only does `echo "$@"` (pinned `lib/bash/home-manager.sh:109-127`), and the `>` redirect belongs to `run` itself. A dry-run activation (e.g. `home-manager switch --dry-run` on the standalone anuramat-linux config, which imports heavy-linux) therefore overwrites `~/.config/codex/config.toml` with the text `cat /nix/store/...-codex-config.toml`.
- There is no `mkdir -p`, so `cat >` fails if `~/.config/codex` does not exist yet; ordering against linkGeneration (which creates it for `codex/AGENTS.md`) is not guaranteed.
- Drift that codex writes into the file is not logged. Six lines earlier the same file uses `config.lib.home.mkGenericActivationScript` for the skill files (codex.nix:30); that helper (`base/lib.nix:43-57`) does `mkdir -p`, logs the diff to `$XDG_STATE_HOME/hm-activation-diffs.txt` and stderr, then `run cp --no-preserve=mode`. History shows `codexConfig` was written on 2025-08-03 (a7173498), a day before the helper existed, so it is a leftover rather than a deliberate choice.

**Fix:** Replace lines 136-138 with `codexConfig = config.lib.home.mkGenericActivationScript codexTomlCfg codexCfgPath;`. Same DAG position (`entryAfter [ "writeBoundary" ]`); keep the `lib` argument, since `mapAttrs'` still uses it. On a live run content and mode behave the same (`cat >` and `cp --no-preserve=mode` onto an existing file both keep its mode). The one intended behavior change: codex-made edits to config.toml (trust entries, notices, desktop settings) now show up in the activation diff log, like every other managed mutable config here.

**Verify:** `nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat.home.activation.codexConfig.data` shows the `mkdir -p`, the diff block and `run cp --no-preserve=mode "$source" "$target"`; `nix flake check` passes. After a switch, `~/.config/codex/config.toml` matches the generated TOML.

### A8. conform: `injected` `ignore_errors` is set at the wrong level and has no effect

**Where:** `nixvim-modules/heavy/default.nix:41-45`
**Effort:** trivial -- **Risk:** low

**Problem:** `formatters = { injected = { ignore_errors = true; }; };` puts the key at the top level of the formatter config. conform's injected formatter reads only `self.options.ignore_errors` (`lua/conform/formatters/injected.lua:294`; default `false` at `:183`), and `doc/formatter_options.md` says to set `formatters.injected = { options = { ignore_errors = true } }`. `get_formatter_config` merges the override with a plain `tbl_deep_extend` (`util.lua:167-168`), so a top-level key never reaches `options`. Checked headless against the current init.lua: `get_formatter_config('injected').options.ignore_errors` is `false`. Result: if one injected block in a .nix or .typ file fails to format, the whole injected pass fails, despite the config asking for errors to be ignored.

**Fix:** Replace the block with `formatters.injected.options.ignore_errors = true;`.

**Verify:** `nix eval --raw .#packages.x86_64-linux.neovim.config.content | grep -o 'injected = {[^}]*}'` shows `injected = { options = { ignore_errors = true` (today it shows `injected = { ignore_errors = true }`); `nix build .#checks.x86_64-linux.neovim` passes.

### A9. gitsigns: `ih` and `ah` select the same thing because `greedy` defaults to true

**Where:** `nixvim-modules/heavy/git.nix:55-62`
**Effort:** trivial -- **Risk:** low

**Problem:** `ih` maps to `require("gitsigns").select_hunk()` and `ah` to `select_hunk({ greedy = true })`. In gitsigns 2.1.0, `select_hunk` calls `bcache:get_hunk(nil, opts.greedy ~= false)` (`actions.lua:583`), and `HunkOpts.greedy` is documented as "Defaults to `true`" (`actions.lua:31-34`). Greedy only matters with linematch, which Neovim's default `diffopt` enables (`linematch:40`). Checked headless with a 2-removed/3-added change that linematch splits into change/add/change hunks: `select_hunk()` and `{ greedy = true }` both select lines 2..4, `{ greedy = false }` selects 2..2. So the inside/around distinction the descriptions promise does not exist.

**Fix:** Line 58 (`ih`): `require("gitsigns").select_hunk({ greedy = false })`. Line 62 (`ah`): `require("gitsigns").select_hunk()`.

**Verify:** `nix build .#checks.x86_64-linux.neovim`. In a buffer with adjacent changed hunks, `vih` selects one hunk and `vah` selects the contiguous group.

### A10. mpv: mpv.conf sets the removed option `cache-default` and the renamed profile `gpu-hq`

**Where:** `home-modules/heavy-linux/gui/viewers.nix:25`, `home-modules/heavy-linux/gui/viewers.nix:19`
**Effort:** trivial -- **Risk:** none

**Problem:** `cache-default = 4000000;` was removed in mpv 0.29. The evaluated mpv is 0.41.0 and the rendered mpv.conf contains `cache-default=%7%4000000`; every start prints `Error parsing option cache-default (option not found)` / `mpv.conf:1: setting option cache-default='4000000' failed.` (reproduced with the generated mpv.conf). `profile = "gpu-hq";` is only a compatibility alias now: `mpv --show-profile=gpu-hq` prints `profile=high-quality`.

**Fix:** Delete line 25 (`cache-default = 4000000;`); it has been a no-op for years, so dropping it keeps current behavior. Change line 19 to `profile = "high-quality";`.

**Verify:** With `H=.#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat` and pipe-operators enabled, `nix eval --raw $H.xdg.configFile."mpv/mpv.conf".text` has no `cache-default` and has `profile=high-quality`. After a rebuild, `mpv --frames=1 somefile` prints no "Error parsing option".

### A11. uc3: the handler uses grep but does not list gnugrep in runtimeInputs

**Where:** `home-modules/heavy-linux/agents/uc3/handler.sh:21`, `home-modules/heavy-linux/agents/uc3/default.nix:12`
**Effort:** trivial -- **Risk:** none

**Problem:** `handler.sh:21` runs `if grep -q 'Permission denied' "$STATE_DIRECTORY/login.err"; then`, but `runtimeInputs = with pkgs; [ coreutils openssh systemd ];` (default.nix:12-16) lists every other tool it uses and not grep. Today grep comes from the user manager's inherited PATH, because the relay receiver runs the handler as a systemd user service (`relay/default.nix:47`). If it is ever missing, grep exits 127 inside the `if`, the else branch runs, and a refused login is reported as "cluster unreachable" without tripping the TOTP breaker -- the safety property the script exists to keep. Checked in a scratch copy: with gnugrep added, the uc3-handler derivation's PATH becomes coreutils, gnugrep, openssh, systemd, and shellcheck passes.

**Fix:** Add `gnugrep` to the uc3-handler `runtimeInputs` list, between `coreutils` and `openssh`. If F15 is applied, its handler list already includes `gnugrep`.

**Verify:** `nix flake check` passes; the uc3-handler script's `PATH=` line contains gnugrep.

### A12. fleet-status: sed and grep are used but not declared in runtimeInputs

**Where:** `home-modules/heavy-linux/desktop/noctalia/fleet-monitor/fleet-status.nix:47`, `home-modules/heavy-linux/desktop/noctalia/fleet-monitor/fleet-status.nix:66`, `home-modules/heavy-linux/desktop/noctalia/fleet-monitor/fleet-status.nix:34`
**Effort:** trivial -- **Risk:** none

**Problem:** `runtimeInputs` (lines 47-53) declares bash, coreutils, findutils, openssh and procps. The host loop runs `printf '%s\n' "$out" | sed "s/^/$h\t/"` (line 66), and for the current host the remote script runs as `run=(bash)` under the wrapper's PATH and calls `grep -v EXITED` (line 34). Both currently come from whatever PATH the noctalia process inherits. (zellij and bgm5powerctl are deliberately taken from the host PATH and stay out.) Reproduced with an empty environment: the local run prints `grep: command not found` and `sed: command not found`.

**Fix:** Add `gnugrep` and `gnused` to the `runtimeInputs` list.

**Verify:** Build the package as `fleet-monitor/default.nix:9` does and run it with an empty environment; it prints the local lines without "command not found":

```sh
p=$(nix build --no-link --print-out-paths --extra-experimental-features pipe-operators --impure --expr 'let f = builtins.getFlake "path:/etc/nixos"; in f.legacyPackages.x86_64-linux.callPackage ./home-modules/heavy-linux/desktop/noctalia/fleet-monitor/fleet-status.nix { inputs = f.inputs // { self = f; }; }')
env -i HOME=$HOME HOSTNAME=$(hostname) "$p/bin/fleet-status" "$(hostname)"
```

### A13. niri shortcuts: shared builder for the iOS shortcut scripts (fixes open-link's missing coreutils)

**Where:** `home-modules/heavy-linux/desktop/niri/shortcuts.nix:21`, `home-modules/heavy-linux/desktop/niri/shortcuts.nix:25`, `home-modules/heavy-linux/desktop/niri/shortcuts.nix:27`
**Effort:** small -- **Risk:** low

**Problem:** Lines 22-66 repeat the same `writeShellApplication { name; inherit excludeShellChecks; runtimeInputs = [ pkgs.findutils ... ]; text = ''${niriEnv} ...''; }` boilerplate three times. `niriEnv` calls `basename` and `cut` (line 15), but open-link's `runtimeInputs` (`pkgs.findutils pkgs.niri pkgs.firefox`) omit coreutils, so it relies on the ambient PATH -- a real undeclared dependency (get-clipboard and set-clipboard do list coreutils). open-link also uses `pkgs.niri` instead of `config.programs.niri.package`, unlike `zsa-tap.nix:26`; the two are equal today (`niri/default.nix:104` sets `package = pkgs.niri`), so that swap is consistency only.

**Fix:**
- Add to the `let`:

```nix
mkShortcut =
  name: deps: body:
  writeShellApplication {
    inherit name excludeShellChecks;
    runtimeInputs = [
      pkgs.findutils
      pkgs.coreutils
    ] ++ deps;
    text = "${niriEnv}\n${body}";
  };
```

- Set `home.packages = [ (mkShortcut "open-link" [ config.programs.niri.package pkgs.firefox ] ''...'') (mkShortcut "get-clipboard" [ pkgs.wl-clipboard ] "wl-paste --no-newline 2>/dev/null || true") (mkShortcut "set-clipboard" [ pkgs.wl-clipboard ] "wl-copy") ];`, where open-link's body is the existing 3-line firefox-PATH comment followed by `niri msg action spawn -- "$(command -v firefox)" "$1"` (keep the comment inside the body).
- The helper keeps using the `excludeShellChecks` binding, so it is compatible with F1.

**Verify:** The three packages build (which runs shellcheck). Over ssh, `open-link https://example.com` opens the page in the niri session, and `echo hi | set-clipboard; get-clipboard` prints `hi`.

### A14. Lua lint step is broken and the Lua tooling is dead (keep `.stylua.toml`)

**Where:** `justfile:36`, `outputs.nix:271`, `parts/treefmt.nix:18`, `.luarc.json:1`, `AGENTS.md:29`
**Effort:** small -- **Risk:** low

**Problem:** The repo has had no `.lua` file since the legacy nvim config was deleted (4fc3139f, 2025-06-16); `git ls-files '*.lua'` is empty, and no markdown in the repo has lua code blocks that otter would hand to lua_ls. On top of that, `justfile:36` `fd -e lua | luacheck - --codes --globals=vim -q` is wrong: `luacheck -` lints stdin as Lua source, so it would check the list of file names rather than the files. Reproduced: `echo a.lua | luacheck - --codes -q` gives `stdin:2:1: (E011)` with rc=2, while `luacheck a.lua` reports the real warnings; with empty stdin it returns 0, so today it always passes. Therefore the step, `luaPackages.luacheck` in the devShell (`outputs.nix:271`), treefmt's `stylua.enable = true;` (`parts/treefmt.nix:18`; the generated treefmt.toml includes only `*.lua`) and `.luarc.json` (lua_ls workspace config) do nothing here. `.stylua.toml` is NOT dead: conform's `injected` formatter (`nixvim-modules/heavy/lang/nix.nix:13`) runs stylua (`lua.nix:3`) on Lua embedded in .nix strings, and stylua picks up this file. `home-modules/heavy/lang/packages.nix:24` (user-wide luacheck) is unrelated and stays.

**Fix:**
- Delete `justfile:36`, `outputs.nix:271` (`luaPackages.luacheck`), `parts/treefmt.nix:18` (`stylua.enable = true;`) and the file `.luarc.json`. Keep `.stylua.toml`.
- AGENTS.md:29-33, combined with A15: "- `nix develop`: enter the dev shell with `just`, `nh`, `nixfmt`, `statix`, `deadnix`, `shellcheck`, and `yamllint`." and "- `just lint`: run statix, deadnix, Nix parsing, shellcheck, and yamllint."
- If Lua linting is wanted later, the correct form is `fd -e lua -X luacheck --codes --globals=vim -q`.

**Verify:** `nix develop -c just lint` passes; `nix develop -c true` works; `nix fmt` still runs and the formatter's treefmt.toml has no `[formatter.stylua]`; `git ls-files '*.lua'` is still empty.

### A15. devShell lacks statix and deadnix, so `just lint` fails from `nix develop`

**Where:** `outputs.nix:259`, `justfile:33`
**Effort:** trivial -- **Risk:** none

**Problem:** `just lint` runs `statix check` and `deadnix` (`justfile:33-34`). The devShell (`outputs.nix:259-272`) carries the other lint tools (`fd`, `shellcheck`, `yamllint`, luacheck) but not these two, which reach PATH only through `home-modules/heavy/lang/packages.nix:22,26`. The heavy layer is imported only via `nixos-modules/local` (and the standalone home configs), so `nix develop -c just lint` fails on anuramat-root or on a machine without this flake's Home Manager. AGENTS.md:29-33 presents the dev shell as the source of the lint tooling. Both evaluate from the overlaid `pkgs` on both systems (`legacyPackages.aarch64-darwin.statix.name` = statix-0.5.8, deadnix-20250904173950), so the darwin devShell keeps evaluating.

**Fix:**
- Add `statix` and `deadnix` to `devShells.default.packages`, next to `nixfmt` (after line 268).
- Update the AGENTS.md:29-30 devShell description to list them (combined wording in A14).

**Verify:** `nix develop --ignore-env -c sh -c 'command -v statix deadnix'` prints both paths; `nix develop -c just lint` passes.

## B. Dead code and leftovers

### B1. Remove the waybar-niri-windows leftovers (input, overlay package, flake check, AGENTS.md bullet)

**Where:** `flake.nix:120`, `overlays/default.nix:156`, `outputs.nix:223`, `AGENTS.md:235`
**Effort:** small -- **Risk:** none

**Problem:** Waybar went away in 027da08a (`noctalia: init`, 2026-09-02), which deleted `home-modules/heavy-linux/desktop/niri/bar.nix`, the only consumer of `module_path = "${pkgs.waybar-niri-windows}/lib/waybar-niri-windows.so"`. `git grep waybar` (excluding flake.lock) now hits only four leftovers: the `waybar-niri-windows = { url = "github:calico32/waybar-niri-windows"; flake = false; };` input (flake.nix:120-123); the `waybar-niri-windows = prev.buildGoModule { ... vendorHash = "sha256-jK87..."; ... };` overlay attr (overlays/default.nix:156-165); the flake check `# hand-pinned vendorHash drift only surfaces at build time, so build it` / `// lib.optionalAttrs (system == "x86_64-linux") { inherit (pkgs) waybar-niri-windows; }` (outputs.nix:223-226); and the AGENTS.md bullet "Waybar's niri-windows plugin is built from the `waybar-niri-windows` flake input..." (AGENTS.md:235-238), which still describes it as live. So every `nix flake check` on x86_64-linux compiles a Go c-shared .so that nothing loads. The check block was added in 7388a617 to catch vendorHash drift, and this package is the only thing left in it. The other hand-pinned vendorHash, kitty's `kitty-go-modules` (overlays/default.nix:85), does not need a replacement check: its src is pinned to tag `v0.49.1` with a fixed hash, so it cannot drift on an input bump.

**Fix:**
- flake.nix: delete the `waybar-niri-windows` input block (lines 120-123).
- overlays/default.nix: delete the `waybar-niri-windows = prev.buildGoModule { ... };` attr (lines 156-165).
- outputs.nix: delete the comment and the `// lib.optionalAttrs (system == "x86_64-linux") { ... }` block (lines 223-226), so the home-check attrset is followed directly by the neovim `// { ... }`. `lib` and `system` are still used elsewhere in the file.
- AGENTS.md: delete the "Waybar's niri-windows plugin ..." bullet (lines 235-238).
- Run `nix flake lock` to prune the node from flake.lock (one run can also cover B2).

**Verify:** `git grep -n waybar -- ':!flake.lock'` is empty; `nix eval .#checks.x86_64-linux --apply builtins.attrNames` no longer lists `waybar-niri-windows`; `nix flake metadata` no longer lists the input; `nix flake check` passes.

### B2. Drop the orphaned llama-cpp-diffusion flake input

**Where:** `flake.nix:57`
**Effort:** trivial -- **Risk:** none

**Problem:** flake.nix:57-61 still declares `# llama.cpp PR 24423: DiffusionGemma support` / `llama-cpp-diffusion = { url = "github:danielhanchen/llama.cpp/diffusion-visual-updates"; flake = false; };`. It was added in 08d43f15; its only consumers (`diffusionGemma` and `llama-cpp-diffusion-{vulkan,rocm}` in the overlay) were removed in cd84ff69 (`overlays: refactor, drop rarely used packages`, 2026-08-28). `git grep llama-cpp-diffusion` (excluding flake.lock) matches only flake.nix. Nothing reads `inputs.llama-cpp-diffusion`; the nix.nix registry/nixPath mapping of all inputs only turns it into an unused registry entry.

**Fix:** Delete flake.nix:57-61 (the comment and the input block), then run `nix flake lock` to prune it from flake.lock. This can share the `nix flake lock` run with B1.

**Verify:** `git grep -n llama-cpp-diffusion -- ':!flake.lock'` is empty; `nix flake lock` succeeds; `nix flake check` passes.

### B3. todo.py: drop the stale `unfiled` subcommand

**Where:** `overlays/todo.py:288`, `overlays/todo.py:315`, `overlays/todo.py:33`
**Effort:** trivial -- **Risk:** low

**Problem:** `subparsers.add_parser("unfiled", help="List unfiled tasks")` (line 288) is still registered, but `_dispatch_command`'s `command_handlers` (lines 315-322) has no `"unfiled"` key, so `todo unfiled` falls into `else: tag_overview()` and prints the tag grid instead of the unfiled list. The missing handler is deliberate: fd4a4ed1 removed `"unfiled": lambda: ls_tag("unfiled")` from `command_handlers` in the same change that introduced `todo ls TAG`, which handles `unfiled` through `_get_tag_dict`. The parser entry is the leftover, so the fix is to finish that removal, not to re-add the handler. Separately, `def get_date(line: str) -> str:` (lines 33-37) is never called today, but D10 makes it the sort key in `merge()` (`result.sort(key=get_date)`).

**Fix:**
- Delete line 288 (`subparsers.add_parser("unfiled", ...)`). `todo ls unfiled` stays the way to list unfiled tasks, and `todo unfiled` becomes an argparse "invalid choice" error instead of silently printing the tag grid.
- Keep `get_date` if D10 lands; delete lines 33-37 only if that fix is skipped.

**Verify:** `just build todo` succeeds (`writePython3Bin` runs flake8); with `TODO_FILE` pointing at a sample file, `todo unfiled` exits with `invalid choice: 'unfiled'` and `todo ls unfiled` still lists only the untagged tasks.

### B4. bgm5: drop the explicit `pkgs.linux-firmware` from `hardware.firmware`

**Where:** `nixos-configurations/anuramat-bgm5/default.nix:54`
**Effort:** trivial -- **Risk:** low

**Problem:** `hardware.firmware = [ pkgs.linux-firmware pkgs.strix-halo-mes-firmware ];`. Base sets `hardware.enableAllFirmware = true`, and all-firmware.nix already adds the same package: `definitionsWithLocations` shows the same `linux-firmware-20260519` outPath coming from both bgm5/default.nix and all-firmware.nix (the overlay pins `linux-firmware` globally, so both refer to one derivation). List order does not decide the MES override either: `compressFirmware` keeps meta, and the `buildEnv` behind `hardware.firmware` honours `meta.priority` (linux-firmware 6, the MES package the default 5), so the MES files win on collisions. The explicit entry was added without rationale in d19cdea7. Built the bgm5 firmware env with and without the entry: all 8081 resolved files are identical, and `amdgpu/gc_11_5_1_mes_2.bin.zst` still comes from `strix-halo-mes-firmware`.

**Fix:** Delete line 54 (`pkgs.linux-firmware`), leaving `hardware.firmware = [ pkgs.strix-halo-mes-firmware # from nix-strix-halo tuning module ];`.

**Verify:** `nix build .#nixosConfigurations.anuramat-bgm5.config.hardware.firmware -o fw-old` before and `-o fw-new` after the change; `diff <(cd fw-old && find -L lib/firmware -type f -printf '%P\n' | sort) <(cd fw-new && find -L lib/firmware -type f -printf '%P\n' | sort)` is empty, and `readlink -f fw-new/lib/firmware/amdgpu/gc_11_5_1_mes_2.bin.zst` points into `strix-halo-mes-firmware`.

### B5. rocm.nix: drop `services.ollama.package`, ollama is never enabled

**Where:** `nixos-modules/base/rocm.nix:15`
**Effort:** trivial -- **Risk:** none

**Problem:** `services.ollama.package = pkgs.ollama-rocm;`. Nothing in the repo enables `services.ollama` (grep finds only this line, the overlay and the `ollama.age` secret name), and git history shows only `acceleration`/`package` were ever set. On bgm5, the only rocmSupport host, eval gives `services.ollama.enable = false`. The line would be redundant even if ollama were enabled: with `nixpkgs.config.rocmSupport = true`, the ollama package sets `rocmRequested` from `config.rocmSupport`, and eval shows `pkgs.ollama.outPath == pkgs.ollama-rocm.outPath`.

**Fix:** Delete line 15 and the blank line before it. `pkgs` is still used in the file.

**Verify:** `nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.system.build.toplevel.drvPath` is unchanged.

### B6. bash: drop `STACK_XDG`, it is ignored because `STACK_ROOT` is set

**Where:** `home-modules/base/bash/default.nix:52`, `home-modules/base/bash/default.nix:53`
**Effort:** trivial -- **Risk:** none

**Problem:** `STACK_ROOT = "${config.xdg.dataHome}/stack"; STACK_XDG = "1";`. In stack 3.9.3, `determineStackRootAndOwnership` (src/Stack/Config.hs:1095-1115) consults `STACK_XDG` only when `STACK_ROOT` is unset, and that is its only use; the Stack docs (topics/stack_root) say the same: "Stack will ignore that configuration if ... the STACK_ROOT environment variable exists." So `STACK_XDG` is dead. Line 52 also uses `config.xdg.dataHome` while the surrounding lines use the local `XDG_DATA_HOME` binding (same value).

**Fix:** Delete line 53 (`STACK_XDG = "1";`); behavior is unchanged. Optionally write line 52 as `STACK_ROOT = "${XDG_DATA_HOME}/stack";` for consistency. (Dropping `STACK_ROOT` instead would move the global config.yaml to ~/.config/stack, which is a behavior change and out of scope.)

**Verify:** `nix eval .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.home.sessionVariables --apply 'v: v ? STACK_XDG'` is false and `STACK_ROOT` evaluates to the same path; `stack path --stack-root` is unchanged.

### B7. search.nix: stop reading `programs.eza`, which is never enabled

**Where:** `home-modules/base/search.nix:9`, `home-modules/base/search.nix:66`
**Effort:** trivial -- **Risk:** none

**Problem:** `eza = getExe config.programs.eza.package;` and `${eza} ${lib.strings.concatStringsSep " " config.programs.eza.extraOptions} --grid "$1"`. No module enables `programs.eza` (grep; evaluates false on f12, root and darwin), so `extraOptions` is always `[]` and the interpolation produces an empty string. eza is installed from base/packages.nix, and `config.programs.eza.package` and `pkgs.eza` evaluate to the same outPath. This is a dead coupling to a disabled module.

**Fix:** Line 9 -> `eza = getExe pkgs.eza;`; line 66 -> `${eza} --grid "$1"`.

**Verify:** The generated preview script contains `.../eza --grid "$1"` (the only difference is one collapsed space); fzf's directory preview still renders.

### B8. Remove the empty home-configurations/.gitignore placeholder

**Where:** `home-configurations/.gitignore:1`
**Effort:** trivial -- **Risk:** none

**Problem:** The file is 0 bytes and was added in e1b9be89 ("added gitignore to keep the dir"). The directory now tracks `anuramat-darwin.nix` and `anuramat-linux.nix`, so it no longer needs a placeholder, and `mapDir` in outputs.nix (lines 11-21) keeps only directories and `*.nix` entries, so outputs are unaffected.

**Fix:** `git rm home-configurations/.gitignore`.

**Verify:** `nix eval .#homeConfigurations --apply builtins.attrNames` is unchanged.

### B9. lib.nix: remove the unreachable `{ }` secrets fallback

**Where:** `home-modules/base/lib.nix:104`, `home-modules/base/lib.nix:109`
**Effort:** trivial -- **Risk:** none

**Problem:** `secrets = if osConfig != null then osConfig.age.secrets else if config ? age then config.age.secrets else { };`. home-modules/base is imported only by nixos-modules/base/default.nix:32 (where `osConfig` is set) and by the two home-configurations, both of which import `standalone`, which imports `inputs.agenix.homeManagerModules.default` (standalone.nix:4). So `config ? age` is always true there and the `{ }` branch is unreachable. It would not even work as a fallback: base/default.nix:14-15 dereferences `config.lib.secrets.uc3-totp.path` / `uc3-pw.path`, which would throw on `{ }`. It is a silent fallback, which the global instructions forbid.

**Fix:** Replace lines 104-110 with `secrets = if osConfig != null then osConfig.age.secrets else config.age.secrets;`.

**Verify:** `nix flake check` (host-* and home-* checks) evaluates; the f12 and anuramat-linux activation package drvPaths are unchanged.

### B10. Drop wl-clip-persist: it is never started and noctalia already keeps the clipboard

**Where:** `home-modules/heavy-linux/packages.nix:36`
**Effort:** trivial -- **Risk:** none

**Problem:** `wl-clip-persist # otherwise clipboard contents disappear on exit` only helps while running as a daemon. Its systemd service lived in desktop/clipboard.nix, which 027da08a (`noctalia: init`) deleted, and nothing else starts it (this line is the only reference in the repo). In the pinned noctalia source, `clipboardKeepFromClosedApps` defaults to true (src/config/config_types.h:1080), application_services.cpp:395-397 applies it regardless of whether history is enabled, and `adoptOrphanedSelection` in clipboard_service.cpp re-offers the selection after its owner exits. Noctalia runs on every heavy-linux host, so the comment is false and the package is dead.

**Fix:** Delete line 36.

**Verify:** `grep -rn wl-clip-persist home-modules` is empty; after a rebuild, copy text from an app, close the app and paste elsewhere: the contents are still there.

### B11. obs.nix: drop the tuna plugin config, the plugin was removed

**Where:** `home-modules/heavy-linux/gui/obs.nix:13`, `home-modules/heavy-linux/gui/obs.nix:1`
**Effort:** trivial -- **Risk:** none

**Problem:** `"obs-studio/plugin_config/tuna/outputs.json".text = lib.generators.toJSON { } tunaCfg;` (inside the `xdg.configFile` block, lines 13-26) configures the obs-tuna plugin. Commit 96fbb203 removed `obs-tuna # song info, not really using since waybar shows the song` from `plugins`, and the current list (lines 5-10) has no tuna, so nothing reads the file. `lib` is used only in that block.

**Fix:** Delete the whole `xdg.configFile = let tunaCfg = ...; in { ... };` block (lines 13-26) and change line 1 to `{ pkgs, ... }:`.

**Verify:** `just lint` (deadnix/statix) is clean for obs.nix; `nix eval .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.xdg.configFile --apply 'f: f ? "obs-studio/plugin_config/tuna/outputs.json"'` is false.

### B12. Python/YAML: drop no-op config (empty files, default-valued options, a stray version pin)

**Where:** `home-modules/heavy/lang/python.nix:10`, `home-modules/heavy/lang/python.nix:15`, `home-modules/heavy/lang/python.nix:17`, `home-modules/heavy/lang/python.nix:23`, `home-modules/heavy/lang/python.nix:28`, `home-modules/heavy/lang/yaml.nix:7`
**Effort:** trivial -- **Risk:** none

**Problem:** Each of these does nothing:
- `PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";` points at `"python/pythonrc".text = "";`. `git show 3bede892` shows the file used to hold a readline-history XDG shim; it was emptied when `PYTHON_HISTORY` (python3 is 3.13) took over, and nothing else references it.
- `"ipython/profile_default/startup/00-default.py".text = "";` is an empty startup script; IPython creates `profile_default` itself.
- `matplotlib.config = { };` is the Home Manager default.
- `"yamlfmt/yamlfmt.yaml".text = toYAML { };` renders `{}`, which equals yamlfmt's defaults, and no tool passes `-conf` pointing at it (nixvim misc.nix:63 just runs `yamlfmt`).
- `python313Packages.ptpython` pins a version, unlike every other `python3Packages.*` use (lang/packages.nix:46,56, jupyter.nix:4); with python3 at 3.13 it is the same derivation as `python3Packages.ptpython`.

**Fix:**
- python.nix: delete line 10 (`PYTHONSTARTUP = ...`) and the whole `xdg.configFile = { ... };` block (lines 14-19).
- python.nix: replace the matplotlib block with `matplotlib.enable = true;`.
- python.nix: change line 28 to `python3Packages.ptpython`.
- yaml.nix: delete lines 7-10 (the `# YAML formatter configuration` comment, the `"yamlfmt/yamlfmt.yaml".text = toYAML { };` entry and the blank line). Keep `toYAML`, which the yamllint config still uses.

**Verify:** `nix eval .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.home.sessionVariables --apply 'v: v ? PYTHONSTARTUP'` is false; `python3` and `ipython` start without errors; `yamlfmt -lint` on a YAML file behaves the same.

### B13. agents: drop the never-exercised null filter in `prependFrontmatter`

**Where:** `home-modules/heavy-linux/agents/default.nix:34`, `home-modules/heavy-linux/agents/default.nix:10`, `home-modules/heavy-linux/agents/frontends/codex.nix:21`
**Effort:** trivial -- **Risk:** none

**Problem:** `fields |> filterAttrs (n: v: v != null)` never filters anything. The only callers pass `{ inherit (v) description; }` (claude.nix:56, omp.nix:14) or `{ name = n; inherit (v) description; }` (codex.nix:21-24), and both commands in commands.nix define string descriptions; a missing description is an eval error, not null. `filterAttrs` is used only on line 34. In a scratch copy without the filter, the HM activationPackage drvPaths were unchanged on all hosts.

**Fix:** Delete line 34 and remove `filterAttrs` from the `inherit (lib)` list on line 10.

**Verify:** The anuramat-bgm5 HM `home.activationPackage.drvPath` is unchanged; `just lint` passes.

### B14. Drop duplicate enables (web-devicons, programs.less) and flash's bogus `grammars` key

**Where:** `nixvim-modules/heavy/misc.nix:25`, `nixvim-modules/base/ui.nix:4`, `home-modules/base/bash/default.nix:124`, `home-modules/base/git/difft.nix:31`, `nixvim-modules/heavy/misc.nix:44`, `nixvim-modules/heavy/misc.nix:3`
**Effort:** trivial -- **Risk:** none

**Problem:**
- `web-devicons.enable = true;` at nixvim-modules/heavy/misc.nix:25 repeats nixvim-modules/base/ui.nix:4, which carries the explanatory comment (`# diffview pulls this in anyway; nixvim deprecated the implicit enable`) and is needed by base's diffview (base/editing.nix:22). heavy is only ever used on top of base (`packages.neovim` in outputs.nix, home-modules/heavy/editor.nix).
- `less = { enable = true; };` at home-modules/base/bash/default.nix:124-126 repeats home-modules/base/git/difft.nix:31-37, which is in the same always-imported base layer and both enables less and sets its `config`.
- In the same misc.nix, `flash.settings.modes.treesitter.grammars = [ pkgs.vimPlugins.nvim-treesitter-parsers.todotxt ];` (line 44) is not a flash option: `grammars` appears nowhere in flash.nvim's Lua or README, so it only embeds a store path into flash's setup table (the generated flash config contains it today). It came from b994cc55, which mis-nested other options the same way. The todotxt grammar is already installed through the default `plugins.treesitter.grammarPackages` (eval: `tree-sitter-todotxt-0.0.0+rev=3937c5c`). With it gone, the `pkgs` argument (line 3) is unused.

This item covers only the duplicated enables. The duplicated `home.packages` entries (`git`, `less`, `tmux` in base, `statix`/`deadnix` in heavy) are a separate, disputed change, see H8; its fix also deletes the same bash/default.nix less block, so whichever lands first takes it.

**Fix:**
- nixvim-modules/heavy/misc.nix: delete line 25 (`web-devicons.enable = true;`), line 44 (`grammars = [ ... ];`) and `pkgs,` from the module arguments (line 3).
- home-modules/base/bash/default.nix: delete the `less = { enable = true; };` block (lines 124-126) inside `programs`.

**Verify:** `nix eval .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.programs.less.enable` is still true; `nix eval --raw .#packages.x86_64-linux.neovim.config.plugins.flash.luaConfig.content | grep -c grammars` returns 0; `nix eval --json .#packages.x86_64-linux.neovim.config.plugins.treesitter.grammarPackages --apply 'ps: builtins.any (p: builtins.match ".*todotxt.*" p.name != null) ps'` is true; `just lint` (deadnix) passes; `nix flake check` passes, including the neovim and neovim-minimal checks.

### B15. nix.nix: drop `lsp.servers.statix`, statix has no LSP mode

**Where:** `nixvim-modules/heavy/lang/nix.nix:19`
**Effort:** trivial -- **Risk:** none

**Problem:** `lsp.servers = { statix.enable = true; ... }`. lspconfig 2.9.0's lsp/statix.lua sets `cmd = { 'statix', 'check', '--stdin' }`, and statix 0.5.8 has no LSP subcommand (`statix --help`: check/dump/explain/fix/list). Fed an LSP initialize message, it prints Nix syntax errors and exits 1. Headless test on a .nix buffer: `vim.lsp.is_enabled('statix')` is true and lsp.log shows `Starting RPC client { cmd = { "statix", "check", "--stdin" } }`, yet only null-ls, nil_ls and copilot attach. statix is already covered by nvim-lint (nix.nix:7-10, diagnostics) and none-ls (nix.nix:15-17, code actions), which keep it in extraPackages, so `config.tools` is unchanged.

**Fix:** Delete `statix.enable = true;` from `plugins.lsp.servers` (line 19). Keep the `lintersByFt` and none-ls `code_actions` statix entries.

**Verify:** `nix eval --raw .#packages.x86_64-linux.neovim.config.content | grep -n statix` shows only the null-ls and lint entries, with no `vim.lsp.enable("statix")`; `nix build .#checks.x86_64-linux.neovim`.

### B16. fzf.nix: `fd_opts` under the `grep` picker is never read

**Where:** `nixvim-modules/heavy/fzf.nix:45-57`
**Effort:** trivial -- **Risk:** none

**Problem:** `let fd_opts = "-c never -t f -t l -HL"; in { grep = { ...; inherit fd_opts; ... }; files = { inherit fd_opts; }; ... }`. In fzf-lua 0.0.2648 only the files provider reads `fd_opts` (providers/files.lua:36,39). config.lua:732 only rewrites it when `render_crlf` is set, which defaults to true only for the command/search history pickers (defaults.lua:1936,1955), not grep; the grep defaults (defaults.lua:957-978) use `rg_opts`/`grep_opts`. So `grep.fd_opts` does nothing.

**Fix:** Drop the `let fd_opts = ...; in` wrapper and the `inherit fd_opts;` under `grep`, and set `files.fd_opts = "-c never -t f -t l -HL";` directly in `settings`. Can be combined with the line-61 change in G6.

**Verify:** `nix eval --raw .#packages.x86_64-linux.neovim.config.content | grep -n fd_opts` shows a single occurrence, under `files`.

### B17. go.nix: drop gopls settings that are defaults or no longer exist

**Where:** `nixvim-modules/heavy/lang/go.nix:6`, `nixvim-modules/heavy/lang/go.nix:17-40`
**Effort:** trivial -- **Risk:** low

**Problem:** Checked against `gopls api-json` from the pinned gopls 0.22.0:
- All seven `hints.* = false` entries are defaults (`hints` defaults to `{}`, every key `default=false`).
- In `codelenses`, `gc_details` no longer exists (valid lenses: generate, regenerate_cgo, test, run_govulncheck, tidy, upgrade_dependency, vendor, vulncheck), and the other five (generate, regenerate_cgo, tidy, upgrade_dependency, vendor) default to true.
- In `analyses`, `unusedvariable` and `unusedwrite` default to true and `useany` is no longer an analyzer; only `shadow = true` (default false) does anything.
- `go.ftp.et = false` repeats the runtime ftplugin, which already does `setlocal noexpandtab` under the default `g:go_recommended_style` (runtime/ftplugin/go.vim:32-33; headless `verbose setlocal et?` reports it as last set there). `g:go_recommended_style` is not set anywhere in the repo.

**Fix:**
- Change `go.ftp = { et = false; ts = 4; };` to `go.ftp.ts = 4;`.
- In `settings.gopls`, replace the `analyses` block with `analyses.shadow = true;` and delete the whole `codelenses` and `hints` blocks. Keep `gofumpt`, `semanticTokens`, `staticcheck` and `usePlaceholders`.

**Verify:** `$(nix eval --raw .#packages.x86_64-linux.neovim.config.plugins.lsp.servers.gopls.package.outPath)/bin/gopls api-json | jq` confirms the defaults; `nix build .#checks.x86_64-linux.neovim`; in a .go buffer, `:set et? ts?` shows `noexpandtab tabstop=4`.

### B18. basic.nix: drop `g:nonfiles` entries that match no installed plugin

**Where:** `nixvim-modules/base/basic.nix:24-25`, `nixvim-modules/base/basic.nix:27`, `nixvim-modules/base/basic.nix:29`
**Effort:** trivial -- **Risk:** none

**Problem:** `nonfiles` (read only by `LM_STL` in base.vim:77) includes `"lazy"`, `"NvimTree"` and `"alpha"`, but no lazy.nvim, nvim-tree or alpha-nvim is enabled anywhere in nixvim-modules (filemgr.nix uses neo-tree and oil). `"lspinfo"` no longer exists either: nvim-lspconfig 2.9.0 defines `:LspInfo` as an alias for `:checkhealth vim.lsp` (plugin/lspconfig.lua:76). Grepping the installed vim-pack-dir finds no plugin that sets any of these four filetypes. The rest are live (`NeogitStatus` and `NeogitPopup` are set by neogit, `null-ls-info` by none-ls info.lua:203).

**Fix:** Remove `"lazy"`, `"lspinfo"`, `"NvimTree"` and `"alpha"` from `nonfiles` (basic.nix:20-32).

**Verify:** `nix eval --json .#packages.x86_64-linux.neovim-minimal.config.globals.nonfiles` no longer lists them; `nix build .#checks.x86_64-linux.neovim-minimal`.

### B19. lua.nix: drop `telemetry`, lua-language-server removed it

**Where:** `nixvim-modules/heavy/lang/lua.nix:15-17`
**Effort:** trivial -- **Risk:** none

**Problem:** `telemetry = { enable = false; };`. The pinned lua-language-server 3.18.1 has no telemetry setting: changelog.md:670 records "`CHG` remove telemetry" (2023-1-16), and `telemetry` has 0 matches in script/config/template.lua and anywhere under script/. While checking this, a separate bug showed up: nixvim already wraps lua_ls settings as `{ Lua = cfg; }` (plugins/lsp/language-servers/default.nix:41-42 in the nixvim input), so the generated config is `settings = { Lua = { Lua = { format..., runtime..., telemetry... } } }` and the whole block, including `runtime.version = "LuaJIT"` and `format.enable = false`, is ignored today.

**Fix:**
- Delete the `telemetry = { enable = false; };` block (lines 15-17).
- Follow-up that changes behavior, so it needs a separate OK: drop the extra `Lua = { ... }` level so it reads `settings = { format.enable = false; runtime.version = "LuaJIT"; };`, which makes lua_ls actually use the LuaJIT runtime and stop formatting.

**Verify:** `grep -c telemetry $(nix eval --raw .#packages.x86_64-linux.neovim.config.plugins.lsp.servers.lua_ls.package.outPath)/share/lua-language-server/script/config/template.lua` returns 0; `nix build .#checks.x86_64-linux.neovim`.

### B20. typst.nix: drop `extraPackages = [ pkgs.typstyle ]`, conform auto-install already adds it

**Where:** `nixvim-modules/heavy/lang/typst.nix:3`
**Effort:** trivial -- **Risk:** none

**Problem:** `extraPackages = [ pkgs.typstyle ];`. conform `autoInstall` is on (heavy/default.nix:39) and resolves formatter names via `pkgs.${name}` (nixvim conform auto-install), so the `typst = [ "typstyle" "injected" ]` entry already adds typstyle to extraPackages (conform default.nix:265). Eval shows `typstyle-0.14.4` twice in extraPackages; without line 3 it appears once, and `config.tools` (consumed by home-modules/heavy/editor.nix) is unchanged.

**Fix:** Delete line 3. `pkgs` stays, since it is still used for chromium.

**Verify:** `nix eval --json .#packages.x86_64-linux.neovim.config.tools --apply 'ps: map (p: p.pname or p.name) (builtins.filter (p: p != null) ps)'` still lists typstyle; `just lint` (deadnix) passes.

### B21. ui.nix: colorizer's `user_default_options.yaml` is not an option

**Where:** `nixvim-modules/base/ui.nix:19`
**Effort:** trivial -- **Risk:** none

**Problem:** `user_default_options = { css = true; yaml = true; };`. The pinned nvim-colorizer.lua (2026-04-07) has no `yaml` option: it is absent from `plugin_user_default_options` (lua/colorizer/config.lua:78-111) and from the alias table (:1158-1162), and no Lua file in the plugin mentions yaml. nixvim passes `user_default_options` through unchanged, and the default `filetypes = { "*" }` (config.lua:370) already covers yaml buffers.

**Fix:** Delete `yaml = true;` (line 19).

**Verify:** `grep -rn yaml $(nix eval --raw .#packages.x86_64-linux.neovim.config.plugins.colorizer.package.outPath)/lua` returns nothing; colors still highlight in a .yaml buffer.

### B22. sh.nix: bashls shfmt settings are unreachable

**Where:** `nixvim-modules/heavy/lang/sh.nix:39-46`
**Effort:** trivial -- **Risk:** low

**Problem:** `bashls = { enable = true; settings.bashIde.shfmt = { binaryNextLine = true; caseIndent = true; simplifyCode = true; }; };` repeats the conform shfmt `prepend_args` on lines 28-32, but bashls never formats:
- Filetype detection gives `ft=sh` for .sh and .bash files and for both bash and sh shebangs (checked headless), so the auto-installed conform shfmt formatter always applies, and conform's `lsp_format = "fallback"` (heavy/default.nix:52) uses LSP only when no conform formatter is available.
- bash-language-server 5.6.0 advertises only `documentFormattingProvider` (server.js:107), and Neovim sets the LSP `formatexpr` only for `rangeFormatting` (runtime lua/vim/lsp.lua:857-861), so `gq` cannot reach bashls either.
- Neovim has no default LSP-format keymap and the repo has no `vim.lsp.buf.format` call; the only remaining paths are a manual `:lua vim.lsp.buf.format()` and otter's explicit export command.

**Fix:** Reduce the block to `lsp.servers.bashls.enable = true;`. The conform shfmt `prepend_args` stay the single source of the shfmt flags.

**Verify:** `grep -rn 'buf.format' nixvim-modules` is empty; `nix build .#checks.x86_64-linux.neovim`; format-on-save of a .sh file is unchanged (shfmt through conform).

## C. Options set to their defaults, duplicated or deprecated

### C1. bgm5: `systemd.watchdog.runtimeTime` was renamed

**Where:** `nixos-configurations/anuramat-bgm5/default.nix:52`
**Effort:** trivial -- **Risk:** none

**Problem:** `systemd.watchdog.runtimeTime = "2m";` produces the only NixOS evaluation warning across all four hosts: "The option `systemd.watchdog.runtimeTime' ... has been renamed to `systemd.settings.Manager.RuntimeWatchdogSec'." nixpkgs `nixos/modules/system/boot/systemd.nix:930-931` has `mkRenamedOptionModule [ "systemd" "watchdog" "runtimeTime" ] [ "systemd" "settings" "Manager" "RuntimeWatchdogSec" ]`, so the old name only works through the rename shim. Checked in a scratch copy: with the new name, the warnings list is empty and the bgm5 toplevel drvPath is identical.

**Fix:** replace line 52 with `systemd.settings.Manager.RuntimeWatchdogSec = "2m";`. Keep the comment on line 51 (`# hard-resets the machine if PID 1 is dead for 2m`).

**Verify:**
- `nix eval --json .#nixosConfigurations.anuramat-bgm5.config.warnings` returns `[]`.
- The bgm5 toplevel drvPath is unchanged. A plain drvPath comparison does not work for any edit, because the flake's own source path ends up in `nix.registry`/`nix.nixPath` (`nixos-modules/base/nix.nix:35-37`) and the git revision in `system.configurationRevision`. Neutralize those (checked: an edit that changes nothing else keeps the drvPath identical), run before and after the change, and compare:

```sh
drv() { nix eval --raw --impure --expr "let f = builtins.getFlake \"git+file://$PWD\"; lib = f.inputs.nixpkgs.lib; in (f.nixosConfigurations.$1.extendModules { modules = [ { nix.registry = lib.mkForce { }; nix.nixPath = lib.mkForce [ ]; system.configurationRevision = lib.mkForce null; } ]; }).config.system.build.toplevel.drvPath"; }
for h in anuramat-bgm5 anuramat-f12 anuramat-root anuramat-t480; do echo "$h $(drv $h)"; done
```

### C2. gitsigns: replace the deprecated `next_hunk`/`prev_hunk` with `nav_hunk`

**Where:** `nixvim-modules/heavy/git.nix:51-52`
**Effort:** trivial -- **Risk:** none

**Problem:** `(setAction "]h" "next_hunk")` and `(setAction "[h" "prev_hunk")` generate `<cmd>Gitsigns next_hunk<cr>` and `<cmd>Gitsigns prev_hunk<cr>`. gitsigns 2.1.0 marks both `@deprecated use [[gitsigns.nav_hunk()]]` (`actions.lua:513,533`; the help marks them DEPRECATED); they survive only as thin wrappers around `nav_hunk`. The command form `Gitsigns nav_hunk next` is supported: `C.nav_hunk(args)` calls `M.nav_hunk(args[1], args)`.

**Fix:** change the two lines to `(setAction "]h" "nav_hunk next")` and `(setAction "[h" "nav_hunk prev")`. In the generated keymap table only the action and desc strings change.

**Verify:** `nix eval --raw .#packages.x86_64-linux.neovim.config.content | grep -o 'Gitsigns nav_hunk [a-z]*'` shows `next` and `prev`; `nix build .#checks.x86_64-linux.neovim`; `]h`/`[h` still jump between hunks in a modified file.

### C3. treesitter: use nixvim's top-level `highlight.enable` instead of the legacy `settings.highlight.enable`

**Where:** `nixvim-modules/base/treesitter.nix:9-11`
**Effort:** trivial -- **Risk:** low

**Problem:** the module sets `treesitter = { enable = true; settings = { highlight.enable = true; }; };`. The pinned nvim-treesitter is the main branch: it has no `nvim-treesitter.configs` module, and its `setup()` only reads `install_dir`. nixvim's treesitter module targets main and has a top-level `plugins.treesitter.highlight.enable` (it currently evaluates to `false`); `settings.highlight.enable` is honored only through a transitional fallback (`plugins/by-name/treesitter/default.nix:272-276`: "TODO: Added 2025-12-18 Check both legacy and new api options", "Add warning after transition period"). The fallback also forwards the key into the generated `require'nvim-treesitter'.setup({ highlight = { enable = true } })`, which main ignores.

**Fix:** replace `settings = { highlight.enable = true; };` with `highlight.enable = true;`. Checked in a scratch copy: the FileType highlight autocmd is unchanged, no warnings appear, and the only diff in the generated Lua is `setup({ highlight = { enable = true } })` -> `setup({ })`. A `setup({ })` call remains because treesitter-textobjects adds an empty `textobjects` key; it is harmless. Otter's treesitter check (`treesitter.highlight.enable || ...`) still passes.

**Verify:** `nix eval .#packages.x86_64-linux.neovim.config.plugins.treesitter.highlight.enable` returns `true`; `nix eval --raw .#packages.x86_64-linux.neovim.config.plugins.treesitter.luaConfig.content | grep setup` no longer shows `highlight`; `nix build .#checks.x86_64-linux.neovim-minimal`; in a `.nix` buffer, `:lua print(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)` prints `true`.

### C4. oil: rename `experimental_watch_for_changes` and drop options at their defaults

**Where:** `nixvim-modules/heavy/filemgr.nix:9`, `nixvim-modules/heavy/filemgr.nix:18-19`, `nixvim-modules/heavy/filemgr.nix:23-32`
**Effort:** trivial -- **Risk:** none

**Problem:** `experimental_watch_for_changes = true;` only works through oil's compatibility shim (oil 2.15.0 `config.lua:433-436`: "This option was renamed because it is no longer experimental"); the current name is `watch_for_changes`. Three more settings repeat oil 2.15.0's defaults: `default_file_explorer = true` (`config.lua:4`), `constrain_cursor = "editable"` (`:51`) and `view_options.sort = [ [ "type" "asc" ] [ "name" "asc" ] ]` (`:97-101`). nixvim's oil module has no special handling for any of these keys.

**Fix:** in the oil `settings`:
- delete `default_file_explorer = true;` (line 9) and `constrain_cursor = "editable";` (line 18);
- rename line 19 to `watch_for_changes = true;`;
- delete the whole `sort = [ ... ];` list (lines 23-32).

Keep `columns`, `delete_to_trash`, `skip_confirm_for_simple_edits`, `show_hidden` and `natural_order`. Checked headless after the change: `watch_for_changes = true`, `default_file_explorer = true`, `constrain_cursor = "editable"` and the sort order are unchanged at runtime.

**Verify:** `nix eval --raw .#packages.x86_64-linux.neovim.config.content | grep -o 'require(.oil.).setup.*'` shows `watch_for_changes = true` and none of the removed keys; `nix build .#checks.x86_64-linux.neovim`; `:lua print(vim.inspect(require("oil.config").view_options.sort))` still prints `{ { "type", "asc" }, { "name", "asc" } }`.

### C5. NixOS options set to their defaults or implied by another module

**Where:** `nixos-modules/local/rice.nix:12`, `nixos-modules/local/default.nix:108-110`, `nixos-modules/local/containers.nix:4`, `nixos-modules/base/net.nix:16`, `nixos-modules/base/net.nix:69`
**Effort:** trivial -- **Risk:** none

**Problem:** each of these restates a default or a value another module already sets (checked against the evaluated option defaults and the nixpkgs/stylix sources):
- `stylix.autoEnable = true;` -- default `true` (stylix `target.nix`).
- `wireplumber = { enable = true; };` -- default is `config.services.pipewire.enable`, which the same `pipewire` block sets to `true` (line 102).
- `containers.enable = true; # common container config files in /etc/containers` -- the podman module sets `virtualisation.containers.enable = true` under `mkIf cfg.enable`, and the `podman` block right below sets `enable = true` (line 6).
- `enable = true;` inside `networking.firewall` -- default `true`.
- `ports = [ 22 ];` in `services.openssh` -- default `[ 22 ]`.

Deleting all five in a scratch copy keeps the toplevel drvPath of all four hosts identical.

Not included: `openFirewall = false;` at `nixos-configurations/anuramat-bgm5/llama.nix:57` is also the llama-cpp default, but it sits next to `host = "0.0.0.0"` and the tailscale-only port opening at `llama.nix:66`, so it documents a deliberate security choice. Keep it.

**Fix:** delete:
- `nixos-modules/local/rice.nix:12` (`stylix.autoEnable = true;`) and the blank line after it;
- the `wireplumber = { enable = true; };` block at `nixos-modules/local/default.nix:108-110`;
- `nixos-modules/local/containers.nix:4`. Note: this removes its trailing comment `# common container config files in /etc/containers` along with it;
- `enable = true;` inside `firewall` at `nixos-modules/base/net.nix:16`;
- `ports = [ 22 ];` at `nixos-modules/base/net.nix:69`.

**Verify:** the neutralized toplevel drvPath from C1 is unchanged for all four hosts. Spot-check on f12: `nix eval --json .#nixosConfigurations.anuramat-f12.config --apply 'c: [ c.stylix.autoEnable c.services.pipewire.wireplumber.enable c.virtualisation.containers.enable c.networking.firewall.enable c.services.openssh.ports ]'` still gives `[true,true,true,true,[22]]`.

### C6. cache.nixos.org substituter and key duplicate the NixOS defaults

**Where:** `nixos-modules/base/nix.nix:12`, `nixos-modules/base/nix.nix:55`
**Effort:** trivial -- **Risk:** low

**Problem:** the `caches` list has `"https://cache.nixos.org"` and `trusted-public-keys` has `"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="`, but nixpkgs `nixos/modules/config/nix.nix:371,373` already adds the key and `substituters = mkAfter [ "https://cache.nixos.org/" ]`. As a result, the evaluated f12 `nix.settings.substituters` contains both `https://cache.nixos.org` and `https://cache.nixos.org/`, and `trusted-public-keys` has the cache.nixos.org key twice. List order does not matter: priority comes from each cache's `nix-cache-info`, as the comment at `nixos-modules/base/hosts.nix:18` already notes (`cache.nixos.org=40, cachix=41`). cache.iog.io and cache.nixos.org are both priority 40, and iog still sorts first after the change. The URL also drops out of `trusted-substituters`, but Nix treats `substituters` entries as trusted, so access is unaffected.

**Fix:** in `nixos-modules/base/nix.nix`, delete `"https://cache.nixos.org"` from `caches` (line 12) and `"cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="` from `trusted-public-keys` (line 55). Keep the `# TODO add missing keys to trusted-public-keys` comment.

**Verify:** `nix eval --json .#nixosConfigurations.anuramat-f12.config.nix.settings --apply 's: { inherit (s) substituters trusted-public-keys; }'` lists cache.nixos.org exactly once in each list (as `https://cache.nixos.org/` and the `cache.nixos.org-1:` key).

### C7. `home-manager.extraSpecialArgs` is set twice in the base layer

**Where:** `nixos-modules/base/default.nix:28-30`, `nixos-modules/base/home.nix:10-12`
**Effort:** trivial -- **Risk:** none

**Problem:** both files set `home-manager.extraSpecialArgs = { inherit inputs; };`, and `default.nix` imports `./home.nix`. `home.nix` holds the global Home Manager plumbing (`backupFileExtension`, `useGlobalPkgs`, `useUserPackages`), so the copy in `default.nix` is the redundant one. The option is attrs-typed, so both definitions merge to the same value. Checked in a scratch copy: with the `default.nix` copy removed, the toplevel drvPaths of all four hosts are identical. `inputs` is still used elsewhere in `default.nix`, so its argument list stays.

**Fix:** delete the `extraSpecialArgs = { inherit inputs; };` attribute (lines 28-30) from the `home-manager` block in `nixos-modules/base/default.nix`; keep the one in `home.nix`.

**Verify:** `nix eval .#nixosConfigurations.anuramat-bgm5.config.home-manager.extraSpecialArgs --apply builtins.attrNames` still gives `[ "inputs" "nixosConfig" ]` (`nixosConfig` is added by Home Manager itself); the neutralized toplevel drvPath from C1 is unchanged for all four hosts; `nix flake check` passes.

### C8. Home Manager options at their defaults (firefox, gtk2, niri)

**Where:** `home-modules/heavy-linux/gui/default.nix:36`, `home-modules/heavy-linux/gui/theme.nix:5`, `home-modules/heavy-linux/desktop/niri/default.nix:117`, `home-modules/heavy-linux/desktop/niri/default.nix:122-124`, `home-modules/heavy-linux/desktop/niri/default.nix:125`, `home-modules/heavy-linux/desktop/niri/default.nix:139`
**Effort:** trivial -- **Risk:** none

**Problem:** each of these restates the default:
- `programs.firefox.package = pkgs.firefox;` -- HM's default is `pkgs.${defaultPackageName}`, which is `firefox` for stateVersion >= 19.09 (`mkFirefoxModule.nix:44-46,221`); the option default has the same drvPath as `pkgs.firefox`.
- `gtk.gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";` -- HM's gtk2 module uses the XDG path when `home.preferXdgDirectories` is set, which base sets (`home-modules/base/default.nix:84`); the default evaluates to `/home/anuramat/.config/gtk-2.0/gtkrc`.
- niri-flake `settings.nix` defaults: `xwayland-satellite.enable` is `optional types.bool true` (the `path` next to it is still needed, because niri's PATH override lacks xwayland-satellite); `spawn-at-startup = [ # { argv = [ ]; } ];` is `optional (listOf type) [ ]`; `overview.workspace-shadow.enable` is `optional types.bool true`; `focus-ring.width = 4` matches the borderish `optional float-or-int 4`. Nothing else in the repo sets these.

Must stay: `focus-ring.enable = true` (niri-flake's `stylix.nix` sets it to `mkDefault false`), firefox `configPath` (its NOTE comment: it silences a stateVersion deprecation warning) and `gtk4.theme` (its default depends on `home.stateVersion`).

**Fix:** delete:
- `home-modules/heavy-linux/gui/default.nix:36` (`package = pkgs.firefox;`);
- `home-modules/heavy-linux/gui/theme.nix:5` (`gtk2.configLocation = ...`); `config` stays in the arguments, since `gtk4.theme` uses it;
- in `home-modules/heavy-linux/desktop/niri/default.nix`: line 117 (`enable = true;` inside `xwayland-satellite`, leaving `xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;`), lines 122-124 (`spawn-at-startup = [ # { argv = [ ]; } ];`), line 125 (`overview.workspace-shadow.enable = true;`) and line 139 (`width = 4;` in `focus-ring`). Keep `focus-ring`'s `enable = true;` and its `# active.color` comment.

Note: deleting `spawn-at-startup` also removes its placeholder comment `# { argv = [ ]; }`; it is unused scaffolding.

**Verify:** with `H=.#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat`, the outputs of `nix eval --raw $H.programs.niri.finalConfig`, `nix eval $H.gtk.gtk2.configLocation` and `nix eval --raw $H.programs.firefox.finalPackage.drvPath` are identical before and after the change.

### C9. pinentry-auto: unused `runtimeInputs` and a `program` equal to the default

**Where:** `home-modules/linux.nix:26`, `home-modules/linux.nix:29-32`, `home-modules/linux.nix:36`, `home-modules/linux.nix:38`, `home-modules/linux.nix:45`
**Effort:** trivial -- **Risk:** none

**Problem:** the wayland branch of `services.gpg-agent.pinentry` builds `pinentry-auto` with `runtimeInputs = [ pkgs.wayprompt pkgs.pinentry-tty ]`, but the script execs `${pkgs.wayprompt}/bin/pinentry-wayprompt` and `${pkgs.pinentry-tty}/bin/pinentry-tty` by absolute path, so the extra PATH entries are never used (neither pinentry spawns helpers). It then sets `program = name;`, but HM's `gpg-agent.nix:348` already defaults `pinentry.program` to `mkOptionDefault (package.meta.mainProgram or "pinentry")`, and `writeShellApplication` sets `meta.mainProgram` to `name` (evaluated on f12: `"pinentry-auto"`). With both gone, the `let name = ...; package = ...; in` wrapper has no purpose. The tty branch's explicit `program = "pinentry-tty"` is needed, because `pkgs.pinentry-tty.meta.mainProgram` is `"pinentry"`.

**Fix:** replace the wayland branch with the following; keep the DISPLAY comment and the absolute exec paths, and leave the tty branch unchanged:

```nix
if config.gui == "wayland" then
  {
    package = pkgs.writeShellApplication {
      name = "pinentry-auto";
      # DISPLAY check so that it still works over ssh
      text = ''
        if [ -v DISPLAY ]; then
          exec ${pkgs.wayprompt}/bin/pinentry-wayprompt "$@"
        else
          exec ${pkgs.pinentry-tty}/bin/pinentry-tty "$@"
        fi
      '';
    };
  }
```

**Verify:** `nix eval .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.services.gpg-agent.pinentry.program` is still `"pinentry-auto"`; the generated `gpg-agent.conf` `pinentry-program` line still points at `.../bin/pinentry-auto`; `nix build .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.services.gpg-agent.pinentry.package` succeeds (shellcheck runs as part of `writeShellApplication`).

### C10. completion: blink-cmp sources and copilot `suggestion.enabled` at their defaults

**Where:** `nixvim-modules/heavy/completion.nix:38-47`, `nixvim-modules/heavy/completion.nix:62`
**Effort:** trivial -- **Risk:** none

**Problem:** `blink-cmp.settings.sources.default = [ "lsp" "path" "snippets" "buffer" ];` is blink.cmp 1.10.2's default (`lua/blink/cmp/config/sources.lua:48`), and nixvim's blink module adds no sources of its own. `copilot-lua.settings.suggestion.enabled = true;` is copilot.lua's default (`config/suggestion.lua:23`). Checked headless after the change: blink's `sources.default` is unchanged and copilot's `suggestion.enabled` is `true`.

**Fix:** reduce the blink-cmp block to `blink-cmp.enable = true;` (dropping `settings`, lines 38-47) and delete `enabled = true;` from `copilot-lua.settings.suggestion` (line 62).

**Verify:** `nix build .#checks.x86_64-linux.neovim`; `:lua print(vim.inspect(require("blink.cmp.config").sources.default))` still prints `{ "lsp", "path", "snippets", "buffer" }`; Copilot still auto-suggests in insert mode.

### C11. lsp `inlayHints = false` and otter `handle_leading_whitespace = true` at their defaults

**Where:** `nixvim-modules/heavy/default.nix:60`, `nixvim-modules/heavy/default.nix:71-73`
**Effort:** trivial -- **Risk:** none

**Problem:** `plugins.lsp.inlayHints = false;` is the default: nixvim aliases it to `lsp.inlayHints.enable` (`plugins/lsp/default.nix:96-98,206`), an `mkEnableOption`, and both defaults evaluate to `false`. `otter.settings.handle_leading_whitespace = true;` is otter 2.14.5's default (`lua/otter/config.lua:65`). The only change in the generated Lua is `require('otter').setup({ handle_leading_whitespace = true })` -> `require('otter').setup({ })`.

**Fix:** delete `inlayHints = false;` (line 60) and otter's `settings = { handle_leading_whitespace = true; };` (lines 71-73). Keep the `# TODO enable for typst?` comment and `autoActivate = false; # TODO`.

**Verify:** `nix eval .#packages.x86_64-linux.neovim.config.plugins.lsp.inlayHints` is still `false`; `nix eval --raw .#packages.x86_64-linux.neovim.config.content | grep -n "require('otter').setup"` shows `setup({ })`; `nix build .#checks.x86_64-linux.neovim`.

### C12. treesitter-context: four settings at the plugin defaults

**Where:** `nixvim-modules/base/treesitter.nix:21`, `nixvim-modules/base/treesitter.nix:24`, `nixvim-modules/base/treesitter.nix:26-27`
**Effort:** trivial -- **Risk:** none

**Problem:** `enable = true; line_numbers = true; trim_scope = "outer"; mode = "cursor";` match nvim-treesitter-context's `default_config` exactly (`lua/treesitter-context/config.lua:50-60`), which is merged with `tbl_deep_extend('force')`. Only `max_lines`, `min_window_height` and `multiline_threshold` differ from the defaults. Checked headless after the change: `enable`, `line_numbers`, `trim_scope`, `mode`, `max_lines` and `multiline_threshold` are identical (`true true outer cursor 1 1`).

**Fix:** reduce the treesitter-context `settings` (lines 20-28) to `max_lines = 1; min_window_height = 20; multiline_threshold = 1;`.

**Verify:** `nix build .#checks.x86_64-linux.neovim-minimal`; the context line still shows, with a line number, in cursor mode.

### C13. base.vim: options set to Neovim defaults

**Where:** `nixvim-modules/base/base.vim:30`, `nixvim-modules/base/base.vim:33`, `nixvim-modules/base/base.vim:47-48`, `nixvim-modules/base/base.vim:55`, `nixvim-modules/base/base.vim:57`
**Effort:** trivial -- **Risk:** none

**Problem:** `nvim --clean` on the pinned Neovim (e728c10) reports these as defaults: `foldenable=true` (`se fen ...`), `incsearch=true` (`se incsearch ...`), `cmdheight=1` (`se cmdheight=1`), `conceallevel=0` (`se cole=0`), `scrolloff=0` (`se scrolloff=0 ...`) and `cursorlineopt=both` (`se cursorline cursorlineopt=both`). base.vim runs first (`mkBefore`), and nothing earlier in init.lua sets these options (only `formatoptions`/`termguicolors`). Checked headless after the change: all six values and `sidescrolloff=30` are identical.

**Fix:** in `nixvim-modules/base/base.vim`:
- line 30 -> `se fdm=indent foldlevelstart=99 " overriden by fdl in modelines`;
- line 33 -> `se ignorecase smartcase " search`;
- delete lines 47 (`se cmdheight=1`) and 48 (`se cole=0`);
- line 55 -> `se sidescrolloff=30`;
- line 57 -> `se cursorline`.

**Verify:** `nix build .#checks.x86_64-linux.neovim-minimal`; in the built Neovim, `:lua for _, o in ipairs({ "cmdheight", "incsearch", "foldenable", "cursorlineopt", "scrolloff", "conceallevel", "sidescrolloff" }) do print(o, vim.inspect(vim.o[o])) end` prints `1 true true "both" 0 0 30`.

### C14. sh.nix: shfmt `"inherit" = true` is conform's default

**Where:** `nixvim-modules/heavy/lang/sh.nix:27`
**Effort:** trivial -- **Risk:** none

**Problem:** `shfmt = { "inherit" = true; prepend_args = [ ... ]; };`. conform treats a nil `inherit` as true (`init.lua:707-710`: `if inherit == nil then inherit = true end`), so the override still extends the built-in shfmt formatter without it. Checked headless: `get_formatter_config('shfmt')` still works after the change, and the generated config only drops `inherit = true`.

**Fix:** delete `"inherit" = true;` at `nixvim-modules/heavy/lang/sh.nix:27`.

**Verify:** `nix build .#checks.x86_64-linux.neovim`; `:ConformInfo` in a `.sh` buffer still lists shfmt, and formatting still applies the prepended args (`--binary-next-line --case-indent --simplify`).

## D. TODOs that can be resolved now

### D1. Drop `boot.initrd.systemd.enable`: systemd stage 1 is the default since NixOS 26.05

**Where:** `nixos-modules/base/default.nix:53` -- `# TODO idk why I have this`
**Effort:** trivial -- **Risk:** none

**Problem:** `boot.initrd.systemd.enable = true; # TODO idk why I have this` switches stage 1 (the initrd) to the systemd-based implementation. On the pinned nixpkgs (26.05pre) that is already the default: `nixos/modules/system/boot/systemd/initrd.nix:185-186` declares `enable = mkEnableOption ... // { default = true; }` unconditionally, and the rl-2605 highlights say "Stage 1 (a.k.a. initrd) is now based on systemd by default, and the old scripted implementation is deprecated". No module in nixpkgs, nixos-hardware, stylix, agenix, niri or nix-strix-halo sets it to false (only perlless and image-based-appliance set `mkDefault true`). Checked: with the line removed, the toplevel drvPaths of all four hosts are identical. Answer to the TODO: the line selects the systemd-based initrd, which is the NixOS default now, so it does nothing.

**Fix:** Delete line 53 together with the blank line 52 before it.

**Verify:** For each HOST in `anuramat-bgm5 anuramat-f12 anuramat-t480 anuramat-root`, `nix eval --raw .#nixosConfigurations.HOST.config.system.build.toplevel.drvPath` is the same before and after.

### D2. nix-ld: drop `openssl` and `stdenv.cc.cc(.lib)`, which the module already provides

**Where:** `nixos-modules/local/default.nix:77` -- `# TODO what is the difference?`, `nixos-modules/local/default.nix:76`, `nixos-modules/local/default.nix:78`, `nixos-modules/local/default.nix:79`
**Effort:** trivial -- **Risk:** none

**Problem:** `programs.nix-ld.libraries` lists `openssl`, then `# TODO what is the difference?` above `stdenv.cc.cc` and `stdenv.cc.cc.lib`. nixpkgs' `programs/nix-ld.nix` builds the library env with `paths = map lib.getLib cfg.libraries`, so `stdenv.cc.cc` resolves to its `lib` output -- the same path as `stdenv.cc.cc.lib`. The module also always adds its own base list (`zlib zstd stdenv.cc.cc curl openssl ...`), which already contains both entries and openssl. The evaluated list on bgm5 has gcc-15.2.0 three times and openssl twice. Checked: the `ld-library-path` env built before and after the change has identical contents (all 747 resolved files). Answer to the TODO: for nix-ld there is no difference -- getLib maps both to the same gcc lib output -- and the module already includes it.

**Fix:** Delete lines 76-79 (`openssl`, the TODO, `stdenv.cc.cc`, `stdenv.cc.cc.lib`), leaving `libraries = with pkgs; [ icu gmp glibc ];`. The nix-ld additions in `nixos-modules/base/cuda.nix` are unaffected.

**Verify:**
- `nix eval --json .#nixosConfigurations.anuramat-f12.config.programs.nix-ld.libraries --apply 'map (p: p.name)'` still contains gcc and openssl, now once each.
- Build the env before and after and compare: `nix build --out-link ld-old "$(nix eval --raw .#nixosConfigurations.anuramat-f12.config.environment.systemPackages --apply 'ps: (builtins.head (builtins.filter (p: (p.name or "") == "ld-library-path") ps)).drvPath')^out"` (likewise `ld-new` after the change), then `diff <(cd ld-old && find -L . | sort) <(cd ld-new && find -L . | sort)` prints nothing.

### D3. Autologin on the getty only on hosts with LUKS, as the TODO asks

**Where:** `nixos-modules/local/default.nix:34` -- `# TODO only if full disk encryption`, `nixos-modules/local/default.nix:33`
**Effort:** trivial -- **Risk:** low

**Problem:** `services.getty = { autologinUser = username; autologinOnce = true; # TODO only if full disk encryption };` autologins on every local host. Of those, bgm5 (`hardware-configuration.nix:35`, root on `/dev/mapper/luks-...`) and f12 (`default.nix:41`, `hardware-configuration.nix:32`) have `boot.initrd.luks.devices`. t480 (deprecated in the `hosts` registry) has plain ext4 and no LUKS devices, so it currently autologins on an unencrypted disk. In nixpkgs' `getty.nix`, `autologinOnce` without `autologinUser` is inert. Checked in a scratch copy: the change evaluates without infinite recursion, giving `"anuramat"` on bgm5 and f12 and `null` on t480. The only behavior change is the one the TODO asks for: t480 stops autologging in.

**Fix:**
- Add `config` and `lib` to the module args: `{ config, lib, pkgs, inputs, ... }:`.
- Change the getty block to:

```nix
  services.getty = {
    autologinUser = lib.mkIf (config.boot.initrd.luks.devices != { }) username;
    autologinOnce = true;
  };
```

**Verify:** `nix eval .#nixosConfigurations.anuramat-bgm5.config.services.getty.autologinUser` and the same for anuramat-f12 give `"anuramat"`; for anuramat-t480 it gives `null`. The bgm5 and f12 toplevel drvPaths are unchanged.

### D4. Remove TODOs that are already done; fix the `agenix(?)` comment

**Where:** `nixos-modules/base/hosts.nix:1` -- `# TODO move`, `nixos-modules/base/nix.nix:9` -- `# TODO add missing keys to trusted-public-keys`, `nixos-configurations/anuramat-root/web/default.nix:11` -- `# TODO: if this works, unboilerplate with a function`, `nixos-modules/base/hosts.nix:37`
**Effort:** trivial -- **Risk:** none

**Problem:** Three TODOs describe work that has already happened, and one comment is wrong:
- `hosts.nix:1` `# TODO move` was added in 53a4dae9 (2025-08-14), when the file was a NixOS module at the repo root (`hosts.nix`). 2d2f5f74 moved it (R100) into `nixos-modules/default/` the same day; that directory is now `nixos-modules/base/`.
- `nix.nix:9` `# TODO add missing keys to trusted-public-keys` comes from 25e850fd, when nixpkgs-python had no key. Today all 9 entries of `caches` have a key at `nix.nix:54-62` (cache.iog.io uses the `hydra.iohk.io` key). C6 removes the cache.nixos.org pair from both lists; the TODO is resolved either way.
- `root/web/default.nix:11` `# TODO: if this works, unboilerplate with a function` (3f56eccf, 2025-04-29) predates the `web.sites` option: `nixos-modules/base/web.nix` now builds vhosts, ACME certs and services through `vhostsFor`/`acmeCertsFor`/`systemdServicesFor` (d8da3fba).
- `hosts.nix:37` `knownHostsFiles = ...; # agenix(?)/ssh host auth`: the only consumer is `net.nix:62` (`programs.ssh.knownHostsFiles`). agenix recipients come from `keys.*.knownHostsKeys` in `secrets/secrets.nix`, not from `config.lib.hosts`, so the `agenix(?)` part is wrong.

**Fix:**
- Delete `nixos-modules/base/hosts.nix:1`, `nixos-modules/base/nix.nix:9` and `nixos-configurations/anuramat-root/web/default.nix:11`.
- Change the trailing comment on `hosts.nix:37` from `# agenix(?)/ssh host auth` to `# ssh host auth`.

**Verify:** `grep -n TODO nixos-modules/base/hosts.nix nixos-modules/base/nix.nix nixos-configurations/anuramat-root/web/default.nix` prints only nix.nix's `# TODO speedFactor, maxJobs`. The toplevel drvPaths are unchanged (comment-only edits).

### D5. Remove the resolved `nix fmt` TODO in the pre-commit hook

**Where:** `parts/pre-commit.nix:2` -- `# TODO nix fmt; wait for https://github.com/cachix/git-hooks.nix/issues/287`
**Effort:** trivial -- **Risk:** none

**Problem:** The upstream issue has been resolved: git-hooks.nix's `flake-module.nix:72` now sets `hooks.treefmt.package = lib.mkIf (options?treefmt) (lib.mkOverride 900 config.treefmt.build.wrapper);`, so the hook uses the treefmt-nix wrapper. The installed `.pre-commit-config.yaml` hook entry is `/nix/store/vy084cyh5l39k8c5rj67vx2dnfv2hadx-treefmt/bin/treefmt --fail-on-change --no-cache`, and `nix eval --raw .#formatter.x86_64-linux.outPath` is the same `/nix/store/vy084cyh5l39k8c5rj67vx2dnfv2hadx-treefmt`. The hook already runs exactly what `nix fmt` runs.

**Fix:** Delete line 2. Keep line 3 (the flake.parts docs link).

**Verify:** After `nix develop` regenerates `.pre-commit-config.yaml`, its treefmt entry starts with the path printed by `nix eval --raw .#formatter.x86_64-linux.outPath`.

### D6. Move `programs.home-manager.enable` to `standalone.nix`: it only installs the `home-manager` CLI

**Where:** `home-modules/base/default.nix:82` -- `# TODO huh? what does this do`, `home-modules/standalone.nix:1`
**Effort:** trivial -- **Risk:** none

**Problem:** `programs.home-manager.enable = true; # TODO huh? what does this do`. HM's `modules/programs/home-manager.nix` is `config = mkIf (cfg.enable && !config.submoduleSupport.enable) { home.packages = [ cfg.package ]; }`. Under the NixOS module `submoduleSupport.enable` is true (evaluated on f12 and t480), so the line is a no-op on every NixOS host and only matters for the standalone configurations. No other HM module reads `programs.home-manager.enable` (auto-expire and auto-upgrade read only `.package`). `home-modules/standalone.nix` is imported only by the two home-configurations. Answer to the TODO: it adds the `home-manager` CLI to `home.packages`, and only in standalone Home Manager.

**Fix:**
- Delete line 82 from `home-modules/base/default.nix`.
- In `home-modules/standalone.nix`, add `programs.home-manager.enable = true; # installs the home-manager CLI` next to `imports`.

**Verify:** `nix eval --raw .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.home.path.drvPath` is unchanged; `nix eval .#homeConfigurations.anuramat-linux.config.programs.home-manager.enable` (and anuramat-darwin) gives `true`; `nix flake check` evaluates.

### D7. bashrc: answer the `history -a` TODO and drop the duplicated `shopt -s globstar`

**Where:** `home-modules/base/bash/bashrc.nix:57` -- `# TODO does this even work/is this required`, `home-modules/base/bash/bashrc.nix:54`, `home-modules/base/bash/bashrc.nix:58`
**Effort:** trivial -- **Risk:** none

**Problem:**
- The TODO sits above `PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND;}history -a"`. It does work: starship's bash init (non-preexec branch) saves an existing PROMPT_COMMAND into `STARSHIP_PROMPT_COMMAND` and runs `eval "$STARSHIP_PROMPT_COMMAND"` in `starship_precmd`; in a live interactive shell `STARSHIP_PROMPT_COMMAND="_direnv_hook;history -a"`. It is not required for history to persist, because HM's default `histappend` shopt already appends on exit, but it flushes each command immediately, so history survives a crash and is visible to new shells. Answer to the TODO: yes, it works; it is not required for persistence, only for immediate per-command writes.
- `shopt -s globstar # enables **` (line 54) duplicates HM's default `programs.bash.shellOptions` (`["histappend" "extglob" "globstar" "checkjobs"]`, unchanged in the f12 and darwin configs), which HM emits as `shopt -s globstar` in the interactive part of `.bashrc` right after `bashrcExtra`. Nothing between line 54 and that point needs globstar, so the end state is the same. The `# enables **` comment goes away with the line.

**Fix:**
- Delete line 54 (`shopt -s globstar # enables **`).
- Replace the line-57 TODO with `# flush each command to $HISTFILE immediately (histappend alone writes on exit); starship evals it via STARSHIP_PROMPT_COMMAND`.

**Verify:** `grep -n 'globstar\|history -a' "$(nix build --print-out-paths --no-link '.#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.home.file.".bashrc".source')"` shows exactly one `shopt -s globstar` (HM's, currently there are two) and the `history -a` line. In a new interactive shell, `shopt globstar` reports `on` and `echo "$STARSHIP_PROMPT_COMMAND"` contains `history -a`.

### D8. Move `TODO_FILE` next to the `todo` CLI in `home-modules/local.nix`

**Where:** `home-modules/base/bash/default.nix:64` -- `# TODO move this somewhere`, `home-modules/base/bash/default.nix:65`, `home-modules/local.nix:8`, `home-modules/heavy-linux/desktop/niri/keys.nix:84`
**Effort:** trivial -- **Risk:** none

**Problem:** `TODO_FILE = "${config.home.homeDirectory}/notes/todo.txt";` sits among the generic XDG variables in the base layer's `home.sessionVariables`. It has two consumers: the `todo` CLI (`overlays/todo.py:14` reads `TODO_FILE`), which is installed only in `home-modules/local.nix:8` (`todo # todo.txt CLI`), and the niri launcher (`keys.nix:84`), which is in heavy-linux and so is always imported together with local. The base-layer git merge driver (`todo merge %A %O %B`) takes explicit file arguments and does not read `TODO_FILE` (`todo.py:239`). anuramat-root (base only) does not have the CLI; anuramat-darwin imports local, so it keeps the variable.

**Fix:**
- Delete lines 64-65 (the TODO and `TODO_FILE = ...`) from `home-modules/base/bash/default.nix`.
- In `home-modules/local.nix`, add `config` to the args and fold the variable into a `home` block:

```nix
  home = {
    packages = with pkgs; [
      ...
    ];
    sessionVariables.TODO_FILE = "${config.home.homeDirectory}/notes/todo.txt";
  };
```

**Verify:** `nix eval .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.home.sessionVariables.TODO_FILE` is unchanged; `.#nixosConfigurations.anuramat-root.config.home-manager.users.anuramat.home.sessionVariables` no longer has it; the anuramat-linux and anuramat-darwin homeConfigurations evaluate.

### D9. Replace the stale `mkImportSet` TODO with a helper shared by overlays and parts

**Where:** `outputs.nix:173` -- `# TODO use mkImportSet as well?`, `outputs.nix:23`, `outputs.nix:190`
**Effort:** trivial -- **Risk:** none

**Problem:** `overlays = mapDir (_name: module: import module { inherit inputs lib; }) ./overlays; # TODO use mkImportSet as well?`. `mkImportSet` no longer exists: 8c10d7af replaced `mkImportSet = mapDir (_: import);` with `mkModuleSet = mapDir (_: path: path);` (line 23), which returns paths and cannot import with arguments, so the TODO points at nothing. The same "import every entry with args" pattern appears again at line 190: `(mapDir (_name: module: import module argsWithInputs) ./parts)`. `mapDir` already filters to `.nix` files and directories, so `overlays/todo.py` is skipped either way. Answer to the TODO: not the old one, which is gone; an args-taking `mkImportSet` serves both overlays and parts.

**Fix:**
- Below `mkModuleSet` (line 23), add `mkImportSet = args: mapDir (_: path: import path args);`.
- Line 173 -> `overlays = mkImportSet { inherit inputs lib; } ./overlays;` (dropping the TODO).
- Line 190 -> `(mkImportSet argsWithInputs ./parts)`.

**Verify:** `nix eval .#overlays --apply builtins.attrNames` gives `[ "default" ]`; `nix eval .#checks.x86_64-linux --apply builtins.attrNames` still lists `pre-commit` and `treefmt`; `nix flake check` passes.

### D10. `todo merge`: sort the merged result by date

**Where:** `overlays/todo.py:256` -- `# TODO sort by date`, `overlays/todo.py:33`
**Effort:** trivial -- **Risk:** low

**Problem:** `merge()` is the git merge driver (`merge.todo.driver = "${lib.getExe pkgs.todo} merge %A %O %B"`, `home-modules/base/git/default.nix:77`). After computing `keep`, it walks `left_lines + right_lines` and appends each kept line once, so lines added only on the right land after all left lines regardless of their dates. Every line starts with an ISO `YYYY-MM-DD ` date (`date_wrap`, `DATE_PATTERN`). `get_date` (lines 33-37) extracts exactly that and has been unused since 74e50a1d (flagged as dead in B3, which keeps it if this fix lands). `result = sorted(keep)` would also work but reorders same-date tasks alphabetically, discarding an order set by hand through `todo edit` (which does not normalize); a stable sort by `get_date` keeps the merge order within a date.

**Fix:** Delete line 256 (`# TODO sort by date`) and add a stable sort after the loop:

```python
    result = []
    for line in left_lines + right_lines:
        if line in keep:
            result.append(line)
            keep.remove(line)
    result.sort(key=get_date)

    write(result, left_name)
```

**Verify:** `just build todo` (writePython3Bin runs flake8). Then in a temp dir: left = `2026-01-01 a`, `2026-01-03 b`, `2026-01-05 left new`; root = `2026-01-01 a`, `2026-01-03 b`; right = `2026-01-01 a`, `2026-01-02 right new`. `result/bin/todo merge left root right` leaves `left` as `2026-01-01 a`, `2026-01-02 right new`, `2026-01-05 left new` (b, removed on the right, is dropped). Checked in a scratch copy with this input.

### D11. Add the `Mod+Escape` shortcuts-inhibit escape bind from the TODO

**Where:** `home-modules/heavy-linux/desktop/niri/keys.nix:206` -- `# TODO Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }`
**Effort:** trivial -- **Risk:** low

**Problem:** The TODO already spells out the bind. Without it, an app that inhibits compositor shortcuts (remmina, VMs) cannot be escaped with a key. The pinned niri-flake supports the action (`memo-binds.nix:16` lists `toggle-keyboard-shortcuts-inhibit`), and `settings.nix:964` says `allow-inhibiting` is implicitly false for it, so it does not need to be set. `Escape` is not bound anywhere else in the niri config, and other no-argument actions in this file use `= { };`.

**Fix:** Replace line 206 with `"Mod+Escape".action.toggle-keyboard-shortcuts-inhibit = { };`. Do not add `allow-inhibiting = false;` (implicit).

**Verify:** `nix build .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.xdg.configFile.niri-config.source` succeeds (niri-flake runs `niri validate -c` on the generated config), and `grep -A1 'Mod+Escape' result` shows `toggle-keyboard-shortcuts-inhibit`.

### D12. hotdoc: ship the PDF placeholder as a store file and close zathura on Ctrl-C

**Where:** `home-modules/heavy/typst.nix:5` -- `# TODO maybe put to a file in nix store`, `home-modules/heavy/typst.nix:24` -- `# TODO close zathura on ctrl-c somehow`, `home-modules/heavy/typst.nix:20`
**Effort:** trivial -- **Risk:** low

**Problem:**
- `pdfPlaceholder` is a base64 string written with `echo '${pdfPlaceholder}' | base64 -d >"$pdf"`. It decodes to five plain-ASCII lines (`%PDF-1.`, `1 0 obj<</Pages 2 0 R>>endobj`, `2 0 obj<</Kids[3 0 R]/Count 1>>endobj`, `3 0 obj<</Parent 2 0 R>>endobj`, `trailer <</Root 1 0 R>>`), so it can be a readable store file. Answer to the TODO: yes, via `pkgs.writeText`.
- zathura is started with `nohup zathura "$pdf" &>/dev/null &` and `disown`, so it outlives the script. A background child of a non-interactive bash ignores SIGINT (checked: SigIgn mask 0x6), so Ctrl-C reaches only `typst watch`. An EXIT trap does run when the script dies from Ctrl-C; checked: sending SIGINT to the script's process group with the trap set kills the background child.
- `trap "kill $!" EXIT` would trigger shellcheck SC2064, and hotdoc's `writeShellApplication` has no `excludeShellChecks`, so the build would fail; the single-quoted form passes and behaves the same, since no other background job starts afterwards.

**Fix:**
- Replace lines 4-6 with the following, which drops the line-5 TODO and the now-outdated "base64 encoded" from the comment:

```nix
  # minimal valid pdf file
  pdfPlaceholder = pkgs.writeText "placeholder.pdf" ''
    %PDF-1.
    1 0 obj<</Pages 2 0 R>>endobj
    2 0 obj<</Kids[3 0 R]/Count 1>>endobj
    3 0 obj<</Parent 2 0 R>>endobj
    trailer <</Root 1 0 R>>
  '';
```

- Change line 20 to `cat ${pdfPlaceholder} >"$pdf"` (`cat` keeps mktemp's 0600 file).
- Replace lines 21-22 (`nohup ... &` and `disown`) with `zathura "$pdf" &>/dev/null &` and `trap 'kill $!' EXIT`.
- Delete line 24 (`# TODO close zathura on ctrl-c somehow`).
- Keep the line-1 `# TODO try removing tmpdir`: it needs a decision and is listed among the TODOs that do.

If zathura is closed first, `kill` prints a harmless "No such process" on exit.

**Verify:** `nix build "$(nix eval --raw .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.home.packages --apply 'ps: (builtins.head (builtins.filter (p: (p.name or "") == "hotdoc") ps)).drvPath')^out"` passes shellcheck. `result/bin/hotdoc test.typ` opens zathura on the blank placeholder, which then reloads the compiled PDF; Ctrl-C closes zathura too.

### D13. Hide the other built-in Firefox search engines, as the TODO asks

**Where:** `home-modules/heavy-linux/gui/default.nix:79` -- `# TODO same for google, ecosia, perplexity, wikipedia`, `home-modules/heavy-linux/gui/default.nix:78`
**Effort:** trivial -- **Risk:** low

**Problem:** `search.engines` hides only Bing (`bing.metaData.hidden = true;`), followed by the TODO. In the pinned HM, `modules/programs/firefox/profiles/search.nix` (`processEngineInput`) treats an engine whose only attribute is `metaData` as app-provided, by id; its `engineNameToId` map has `google`, `ecosia` and `wikipedia` (en; the locale is en_US) (lines 226-259), and `perplexity` is Firefox's built-in id. An id Firefox does not ship is harmless. `lib` is already a module argument.

**Fix:** Delete lines 78-79 and merge the hidden engines into `engines` after `kagi`:

```nix
          engines = {
            kagi = {
              ...
            };
          }
          // lib.genAttrs [ "bing" "google" "ecosia" "perplexity" "wikipedia" ] (_: {
            metaData.hidden = true;
          });
```

**Verify:** `nix eval --json .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.programs.firefox.profiles.default.search.engines` shows `metaData.hidden = true` for all five. After a rebuild and a Firefox restart, `about:preferences#search` lists none of them.

### D14. Drop the answered quoting question on zathura's `synctex-editor-command`

**Where:** `home-modules/heavy-linux/gui/viewers.nix:12` -- `# result should be quoted I think`
**Effort:** trivial -- **Risk:** none

**Problem:** `synctex-editor-command = "texlab inverse-search -i %{input} -l %{line}"; # result should be quoted I think`. HM already quotes it: the rendered zathurarc has `set synctex-editor-command\t"texlab inverse-search -i %{input} -l %{line}"`. Zathura also splits the command with `g_shell_parse_argv` first and only then substitutes `%{input}`/`%{line}` inside each argv element before `g_spawn_async` (`zathura/synctex.c:104-112` in the pinned zathura), so paths with spaces are safe without extra quoting. Answer to the question: the value is quoted, and the placeholders need no quoting.

**Fix:** Delete the trailing comment `# result should be quoted I think`.

**Verify:** `nix eval --raw '.#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.xdg.configFile."zathura/zathurarc".text' | grep synctex-editor` shows the quoted value.

### D15. Rename `scriptCommon` to `preamble` in `mkPackages`

**Where:** `home-modules/heavy-linux/agents/sandbox.nix:128` -- `# TODO rename -- reflect that it's a preamble`, `home-modules/heavy-linux/agents/sandbox.nix:129`, `home-modules/heavy-linux/agents/sandbox.nix:140`, `home-modules/heavy-linux/agents/sandbox.nix:193`
**Effort:** trivial -- **Risk:** none

**Problem:** `scriptCommon` (line 129: `unset GIT_EXTERNAL_DIFF`, the agenix export script and the env export script) is the shared head of both the passthrough script (line 140) and the sandboxed wrapper script (line 193); grep finds no other occurrence in the repo. The TODO asks for a name that says so. Checked: a scratch-copy rename leaves every host's HM drvPaths unchanged.

**Fix:** Delete the TODO on line 128 and rename `scriptCommon` to `preamble` on lines 129, 140 and 193.

**Verify:** `nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat.home.path.drvPath` is unchanged; `nix flake check` passes.

### D16. Replace `mkPrompts` with one command-file helper shared by claude and omp

**Where:** `home-modules/heavy-linux/agents/default.nix:46` -- `# TODO inline?`, `home-modules/heavy-linux/agents/default.nix:47`, `home-modules/heavy-linux/agents/frontends/claude.nix:8`, `home-modules/heavy-linux/agents/frontends/claude.nix:54`, `home-modules/heavy-linux/agents/frontends/omp.nix:3`, `home-modules/heavy-linux/agents/frontends/omp.nix:12`
**Effort:** small -- **Risk:** low

**Problem:** `mkPrompts = dir: prompts: lib.mapAttrs' (...)` (lines 46-54, under `# TODO inline?`) has exactly two callers, and both first run the same mapping:
- `claude.nix:54-58`: `adaptedCommands = agents.commands |> mapAttrs (_: v: v.withFM { inherit (v) description; });` then `agents.mkPrompts "claude/commands" adaptedCommands`.
- `omp.nix:12-15`: `agents.commands |> lib.mapAttrs (_: v: v.withFM { inherit (v) description; }) |> agents.mkPrompts "omp/commands"`.

Inlining `mkPrompts` would duplicate the `mapAttrs'` at both call sites; the real duplication is the shared preprocessing. `mkPrompts`, `withFM` and `agents.commands` appear nowhere else (git grep); codex.nix builds skills differently (adds `name`, uses activation scripts), so it stays separate. `lib.agents` definitions merge shallowly and the helper body is lazy, so reading `config.lib.agents.commands` inside it causes no recursion. Checked in a scratch copy: `home.path` and `home.activationPackage` drvPaths stay identical on all four hosts and in both homeConfigurations. After the change omp.nix no longer uses `lib`, and `deadnix -l` (as run by `just lint`) would report `Unused lambda pattern: lib`; claude.nix still uses `lib.mapAttrsToList`, so its `lib` stays. Answer to the TODO: no -- fold the duplicated preprocessing into the helper instead.

**Fix:**
- `agents/default.nix`: add `config` to the args, and replace `# TODO inline?` and the whole `mkPrompts` binding with:

```nix
    mkCommandFiles =
      dir:
      config.lib.agents.commands
      |> lib.mapAttrs' (
        n: v: lib.nameValuePair "${dir}/${n}.md" { text = v.withFM { inherit (v) description; }; }
      );
```

- `frontends/claude.nix`: delete the `commands` let binding (lines 54-58) and `inherit (lib) mapAttrs;` (line 8, its only use), and write `xdg.configFile = { "claude/CLAUDE.md".text = agents.instructions.claude; } // agents.mkCommandFiles "claude/commands";`.
- `frontends/omp.nix`: delete the `commands` let binding (lines 12-15), use `// agents.mkCommandFiles "omp/commands"` in `xdg.configFile`, and drop the now-unused `lib` arg (line 3).

B13 edits `agents/default.nix` (lines 10 and 34) and F16 edits `omp.nix` (lines 17 and 21); the edits are independent, but line numbers shift.

**Verify:** `nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat.home.activationPackage.drvPath` is the same before and after (the generated `claude/commands/*.md` and `omp/commands/*.md` are unchanged); `deadnix -l` is clean; `nix flake check` passes.

### D17. base.vim: none of the bangs are needed

**Where:** `nixvim-modules/base/base.vim:2` -- `" TODO: maybe remove bangs where not necessary?`, `nixvim-modules/base/base.vim:9`, `nixvim-modules/base/base.vim:66-69`, `nixvim-modules/base/base.vim:74`
**Effort:** trivial -- **Risk:** low

**Problem:** The only bangs are `function! ToggleQuickFix()` (line 9), `function! LM_STL()` (line 74) and `autocmd!` inside `augroup qf` (lines 66-69). They exist only so the file can be re-sourced safely, which never happens: nixvim inlines `base.vim` into a store-path `init.lua` that runs once, and nothing in the repo re-sources it (no `MYVIMRC`/`source` uses). The file is not re-source-safe anyway, since line 53 `au TextYankPost * lua vim.hl.hl_op()` is a bare autocmd outside any augroup. `ToggleQuickFix` and `LM_STL` are referenced only in `base.vim`. Checked: a headless run with the modified init shows no startup messages, and the quickfix buffer is still `nobuflisted`. Answer to the TODO: yes, all of them can go.

**Fix:**
- Delete line 2 (the TODO).
- Change `function!` to `function` on lines 9 and 74.
- Replace the 4-line `augroup qf` ... `augroup END` block (lines 66-69) with `au FileType qf setl nobuflisted`, keeping the `" hide qf buffers:` comment on line 65.

**Verify:** `nix build .#checks.x86_64-linux.neovim-minimal .#checks.x86_64-linux.neovim` (both start nvim headless). In `nix run .#neovim-minimal`, after `:copen`, `:ls` does not list the quickfix buffer.

### D18. Drop the "format twice (conform + otter)" TODO: otter cannot format

**Where:** `nixvim-modules/heavy/default.nix:69` -- `# TODO make sure it doesn't format twice (conform + otter)`
**Effort:** trivial -- **Risk:** none

**Problem:** otter-ls 2.14.5 advertises no formatting capability: its initialize result (`lua/otter/lsp/init.lua:54-67`) lists only hover, definition, implementation, declaration, signatureHelp, typeDefinition, rename, references, documentSymbol and completion, and it registers nothing dynamically. So conform's `lsp_format = "fallback"` (line 52) can never pick otter. Otter's only `vim.lsp.buf.format` calls are inside its explicit export commands (`keeper.lua:629,651`), on hidden otter buffers, and markdown has no `formatters_by_ft` entry. Answer to the TODO: it cannot format twice. C11 edits the same `otter` block (lines 71-73); the edits are independent.

**Fix:** Delete line 69. Keep `# lsp for codeblocks in markdown` on line 68.

**Verify:** `sed -n 54,67p "$(nix eval --raw .#packages.x86_64-linux.neovim.config.plugins.otter.package.outPath)/lua/otter/lsp/init.lua"` shows no `documentFormattingProvider` or `documentRangeFormattingProvider`.

## E. Stale docs

### E1. AGENTS.md describes removed features, ignores the `deprecated` host flag, and has incomplete consumer lists

**Where:** `AGENTS.md:34`, `AGENTS.md:75`, `AGENTS.md:86`, `AGENTS.md:96`, `AGENTS.md:118`, `AGENTS.md:123`, `AGENTS.md:150`, `AGENTS.md:172`, `AGENTS.md:187`, `AGENTS.md:210`, `outputs.nix:89`, `outputs.nix:196`
**Effort:** small -- **Risk:** none

**Problem:** AGENTS.md (the file CLAUDE.md symlinks to, so it is loaded into every agent session) contradicts the code in several passages. Background for the "every host" claims: the registry has a `deprecated` field (default `deprecated = false;` at outputs.nix:89, `deprecated = true;` for anuramat-t480 at outputs.nix:109) that six consumers filter on: `checks` (outputs.nix:196, `!host.deprecated && host.system == system`), builders and, through them, the default substituters (nixos-modules/base/hosts.nix:15), ssh config entries (home-modules/base/default.nix:28), hostrun prompt hosts (home-modules/heavy-linux/agents/hostrun/default.nix:19), agent instructions (home-modules/heavy-linux/agents/instructions.nix:6) and the fleet monitor (home-modules/heavy-linux/desktop/noctalia/fleet-monitor/fleet-status.nix:17). Deprecated hosts keep their trust: `names` in nixos-modules/base/hosts.nix is unfiltered, so their client keys, known_hosts, cache keys and trusted-substituters stay, and secrets/secrets.nix still encrypts to them. Per passage:

- `AGENTS.md:34-35`: "the `checks` output evaluates every host's toplevel" is false for t480 (outputs.nix:196).
- `AGENTS.md:75-79`: the registry is described as `{ system, builder, agent, local }` "plus a `description` on agent hosts" and an optional `alias` ("every host gets an ssh config entry"). `deprecated` is never mentioned; the outputs.nix:78-80 comment says "`description` is required" and every entry has one (it is only rendered for agent hosts, instructions.nix:7); home-modules/base/default.nix:28 drops deprecated hosts from the ssh config.
- `AGENTS.md:85-88`: "the per-host `checks.SYSTEM.host-NAME` outputs evaluate every host's toplevel, so `nix flake check` catches drift on all hosts" is false: t480 gets no check.
- `AGENTS.md:96-98`: the `consts.user` consumer list `nixos-modules/base/{user,net,nix,web,external_keys,default}.nix` misses nixos-modules/base/agent.nix:28,35,51 (`inputs.self.consts.user.username`), and the Home Manager side misses home-modules/base/bash/default.nix:48 (`LC_ALL = inputs.self.consts.user.locale;`). The per-host `home-manager.users.${...}` uses are already covered by the "Per-host Home Manager overrides" sentence.
- `AGENTS.md:118-121`: `keys` is "consumed by `nixos-modules/base/hosts.nix` and `secrets/secrets.nix`", but home-modules/heavy-linux/agents/sandbox.nix:55 reads it too (`inputs.self.keys |> lib.mapAttrsToList (_: k: k.knownHostsFile)`, the sandbox ssh_config's `GlobalKnownHostsFile`); only the separate agent.nix paragraph at :179 hints at it.
- `AGENTS.md:123-126`: "the flake-parts modules under `parts/` (treefmt, pre-commit, nix-topology)": parts/topology.nix was deleted in 941c9782 ("flake: drop topology"), and `parts/` now holds only pre-commit.nix and treefmt.nix. The sentence also omits `legacyPackages = pkgs;` (outputs.nix:192).
- `AGENTS.md:150-151`: t480 is listed as a plain "ThinkPad T480 laptop"; its registry description is "old thinkpad, not actively used" and it is deprecated.
- `AGENTS.md:172-174`: "`nixos-modules/base/builder.nix` ... asserts `!config.nix.distributedBuilds`". builder.nix has no assertions and only creates the `builder` account; since 6d077587 ("builder: refactor: enable via self.hosts") the invariant holds by construction at nixos-modules/base/nix.nix:30 (`distributedBuilds = !inputs.self.hosts.${config.networking.hostName}.builder;`).
- `AGENTS.md:187-190`: overlays/default.nix supposedly has "impure `npx`/`uv tool run` wrappers, and a Proton Bridge source override". The wrappers were dropped in cd84ff69 and protonmail-bridge in a6c12efa. The overlay now composes `overrides` (unstable/unstable-slow pins plus local definitions and overrides such as kitty, yazi-unwrapped, darktable, proton-drive-cli and vim plugins), `flakes` (packages from flake inputs), and the neovim-nightly and oh-my-pi overlays (overlays/default.nix:268-273).
- `AGENTS.md:210-212`: "`codex-remote` has a gated systemd user service ...". It was removed in 3ac6f7c5 ("codex: drop remote-control"); `git grep codex-remote` only hits AGENTS.md.

**Fix:** edit AGENTS.md, keeping its 80-column wrapping:

- `AGENTS.md:34`: "evaluates every non-deprecated host's toplevel".
- `AGENTS.md:75-79`: "`hosts`: a hand-written static registry of `{ system, builder, agent, local, alias, deprecated }` per host plus a required `description` (rendered into the agents' ssh instructions for agent hosts by `home-modules/heavy-linux/agents/instructions.nix`); `alias` is an optional ssh alias (every non-deprecated host gets an ssh config entry in `home-modules/base/default.nix`, under its alias if it has one). `deprecated` hosts (t480) are left out of the `checks.SYSTEM.host-NAME` outputs, remote builders and default substituters, ssh config entries, agent instructions, hostrun and the fleet monitor, but keep their keys and trust (`names` in `nixos-modules/base/hosts.nix` is unfiltered)."
- `AGENTS.md:86-88`: "evaluate every non-deprecated host's toplevel, so `nix flake check` catches drift on those hosts".
- `AGENTS.md:96`: `nixos-modules/base/{agent,user,net,nix,web,external_keys,default}.nix`; `AGENTS.md:98`: after "`home-modules/base/git/` (Git identity)," add "`home-modules/base/bash/` (`LC_ALL` locale),".
- `AGENTS.md:120-121`: "consumed by `nixos-modules/base/hosts.nix`, `home-modules/heavy-linux/agents/sandbox.nix` (the sandbox ssh_config's `GlobalKnownHostsFile`) and `secrets/secrets.nix`".
- `AGENTS.md:125-126`: "`devShells.default`, `legacyPackages` (the overlaid nixpkgs), and the flake-parts modules under `parts/` (treefmt, pre-commit)."
- `AGENTS.md:151`: "`anuramat-t480` (ThinkPad T480 laptop, deprecated)".
- `AGENTS.md:172-174`: "- `nixos-modules/base/nix.nix` sets `nix.distributedBuilds = !hosts.${hostName}.builder`, so a host flagged `builder` is a build server, never a distributed-build client; `nixos-modules/base/builder.nix` only creates the `builder` account there."
- `AGENTS.md:187-190`: "- `overlays/default.nix` mixes unstable and unstable-slow package pins, packages from flake inputs, local package definitions and overrides (kitty, yazi, darktable, proton-drive-cli, vim plugins, ...), and the neovim-nightly and oh-my-pi overlays. Since the base NixOS module applies it globally, overlay edits can affect system packages, Home Manager, and nixvim."
- `AGENTS.md:210-212`: delete the `codex-remote` bullet.
- Not here, fixed together with their code changes: `AGENTS.md:29-33` (dev shell tools and `just lint`) in A15 and A14; `AGENTS.md:112-114` (`consts.builder` consumers) in H1; `AGENTS.md:235-238` (the waybar paragraph) in B1.

**Verify:**

- `git grep -nE 'nix-topology|npx|uv tool run|Proton Bridge|codex-remote|asserts .!config' AGENTS.md` prints nothing; `ls parts/` matches the per-system sentence.
- Every match of `git grep -n '\.deprecated' -- '*.nix'` is named in the new registry text.
- Every file from `git grep -ln 'consts\.user' -- nixos-modules home-modules shared-modules` and `git grep -ln 'self\.keys' -- '*.nix'` appears in the updated consumer lists.
- `nix eval .#checks.x86_64-linux --apply builtins.attrNames` has no `host-anuramat-t480`, as the doc now says.

### E2. README: answer the nix-cache-keygen XXX and the gh ssh-key TODO

**Where:** `README.md:52`, `README.md:54`, `README.md:55`
**Effort:** trivial -- **Risk:** none

**Problem:** README.md:52 reads `nix-cache-keygen # only if this machine is a builder XXX am I sure about this? seems like we need it regardless`. The code answers it: every host needs the key. nixos-modules/base/nix.nix:41 sets `secret-key-files = "/etc/nix/cache.pem"` and nix.nix:86-90 enables harmonia with `signKeyPaths = [ "/etc/nix/cache.pem" ]`, both unconditionally; outputs.nix:163 reads `keys/cache.pem.pub` for every host (all four hosts have one), and nixos-modules/base/hosts.nix:38 puts every other host's cache key into `trusted-public-keys`. The script also creates the `~/.ssh` key (home-modules/base/bin/default.nix:45), which every host needs as well. Caveat: its `sudo chown '${builder}:${builder}' '${private}' '${public}'` (home-modules/base/bin/default.nix:44) aborts under `set -e` on hosts without the `builder` account (created only on `builder = true` hosts, nixos-modules/base/builder.nix:12), i.e. f12, root and t480, before the ssh-keygen step, so the corrected README step fails there until the chown is settled in H1. README.md:55 reads `# TODO upload ssh key to github; might be doable with gh auth`. It is: `gh auth login --help` says "Specifying `ssh` for the git protocol will detect existing SSH keys to upload" (`-p, --git-protocol {ssh|https}`; opt out with `--skip-ssh-key`).

**Fix:**

- README.md:52 -> `nix-cache-keygen # every host: nix and harmonia sign with /etc/nix/cache.pem, outputs.nix reads each host's keys/cache.pem.pub; also creates ~/.ssh keys`.
- README.md:54-55 -> one line, `gh auth login -p ssh # offers to upload the ~/.ssh public key`. This removes the `# TODO upload ssh key ...` comment, since it is answered.
- Changing the script's chown is a separate decision, tracked in H1.

**Verify:** re-read README.md against nixos-modules/base/nix.nix:41,86-90 and outputs.nix:163; `gh auth login --help | grep -i ssh` shows the upload behavior; `git grep -n 'XXX am I sure' README.md` prints nothing.

### E3. README: the new-host step misses the `hosts` registry; the buildMachines workaround names the removed anuramat-ll7 and is duplicated in nix.nix

**Where:** `README.md:9`, `README.md:61`, `README.md:64`, `nixos-modules/base/nix.nix:68`
**Effort:** trivial -- **Risk:** none

**Problem:**

- Install step 0 (README.md:9) says only "prepare a minimal config in `nixos-configurations/$HOSTNAME/default.nix`". Every directory there is evaluated with `lib.optional inputs.self.hosts.${name}.local ...` (outputs.nix:61), and nixos-modules/base/hosts.nix:24 asserts that the registry and `nixosConfigurations` have the same names, so a new host without an entry in `hosts` in outputs.nix fails to evaluate.
- README.md:59-69 ("Problems") and the comment at nixos-modules/base/nix.nix:68-77 carry the same /root/.ssh/config workaround for NixOS/nix#3423 (`sshKey`/`sshUser` ignored), with `Host anuramat-ll7`. anuramat-ll7 no longer exists (the registry has bgm5, f12, root and t480), and the only `builder = true` host is anuramat-bgm5 (outputs.nix:95); `git grep ll7` hits only these two places. The rest of the snippet matches the module: `User builder` is `consts.builder.username` and `IdentityFile /home/anuramat/.ssh/id_ed25519` is `keyPath` (nix.nix:21,79-80).

**Fix:**

- README.md:9 -> "0. prepare a minimal config in `nixos-configurations/$HOSTNAME/default.nix` and add `$HOSTNAME` to `hosts` in `outputs.nix`".
- README.md:61-64: say the block is needed for each `builder = true` host in `hosts` (outputs.nix), and change `Host anuramat-ll7` to `Host anuramat-bgm5`.
- nixos-modules/base/nix.nix:68-77: replace the comment block (from `# sshKey and sshUser are ignored for some reason BUG` through the closing fence) with `# sshKey/sshUser are ignored (NixOS/nix#3423); see README.md "Problems"`, and keep `# TODO speedFactor, maxJobs`. This removes the nix.nix copy of the snippet, which is outdated (it names a host that no longer exists); the README keeps the only copy.

**Verify:** `git grep -n ll7` prints nothing; `nix flake check` still passes (comment-only change in nix.nix).

### E4. docs/standalone-hm.md imports modules that don't exist and names the wrong registration step

**Where:** `docs/standalone-hm.md:4`, `docs/standalone-hm.md:11`, `docs/standalone-hm.md:13`, `docs/standalone-hm.md:19`, `outputs.nix:27`
**Effort:** trivial -- **Risk:** none

**Problem:** docs/standalone-hm.md:3-5 says to "add an entry to the builder in `outputs.nix`", but the step is a `homeSystems` entry (outputs.nix:26-30): outputs.nix:70 looks up `homeSystems.${name}` for every config, and outputs.nix:208-222 turns each entry into `checks.SYSTEM.home-NAME`. The example (lines 7-27) imports `default` and `anuramat` from `inputs.self.homeModules`, neither of which exists (home-modules/ has base, darwin, heavy, heavy-linux, linux, local, local-linux and standalone). It hardcodes `username = "anuramat";` (line 19), where AGENTS.md requires `inputs.self.consts.user`, and uses `stateVersion = "25.05"`, while both real configs use 25.11. The doc was moved here in e1b9be89 ("hm: move hm example to docs") when home-configurations/ was empty; home-configurations/anuramat-darwin.nix and anuramat-linux.nix now evaluate and serve as templates. No other file links to the doc.

**Fix:** replace the body (lines 3-27) with prose pointing at the real files and drop the snippet, so it cannot drift again: "Write `home-configurations/$NAME.nix` (or `home-configurations/$NAME/default.nix`), modeled on `home-configurations/anuramat-linux.nix` / `anuramat-darwin.nix`: import `standalone` plus the layers for that platform, and take `username` from `inputs.self.consts.user`. Then add `$NAME = "$SYSTEM";` to `homeSystems` in `outputs.nix`; that entry also creates `checks.$SYSTEM.home-$NAME`."

**Verify:** every module the doc names exists in `nix eval .#homeModules --apply builtins.attrNames`; the steps match outputs.nix:26-30 and :208-222; `nix eval .#checks.x86_64-linux --apply builtins.attrNames` lists `home-anuramat-linux`.

### E5. docs/luks.md says /tmp is tmpfs on bgm5; it isn't (plus non-ASCII dashes)

**Where:** `docs/luks.md:55`, `docs/luks.md:14`, `nixos-configurations/anuramat-bgm5/default.nix:96`
**Effort:** trivial -- **Risk:** none

**Problem:** The Option 1 caveat at docs/luks.md:55 says "Swap is zram and `/tmp` is tmpfs on this host, so neither leaks to disk." For bgm5, `nix eval .#nixosConfigurations.anuramat-bgm5.config.boot.tmp.useTmpfs` is `false` (nothing in the repo sets it), its fileSystems are only `/`, `/boot` and `/mnt/storage`, and nixos-configurations/anuramat-bgm5/default.nix:96 still has `# TODO tmpfs` above `zramSwap.enable = true;`. Only the swap half holds (`zramSwap.enable` is true, `swapDevices` is empty): /tmp lives on the LUKS root, so under option 1 it is only as protected as the TPM-unlocked root. The file also uses em dashes on lines 14, 19, 44, 47, 61, 73, 95, 97 and 119, against the plain-ASCII rule.

**Fix:**

- docs/luks.md:55 -> "- Swap is zram, so it never leaks to disk; `/tmp` is not tmpfs on bgm5 yet (`# TODO tmpfs` in nixos-configurations/anuramat-bgm5/default.nix), so it lives on the root fs and is only as protected as root."
- Replace every em dash in docs/luks.md (lines 14, 19, 44, 47, 61, 73, 95, 97, 119) with `--`.
- Enabling `boot.tmp.useTmpfs` on bgm5 (which would make the original sentence true) is a separate decision for the user.

**Verify:** `grep -nP '[^\x00-\x7F]' docs/luks.md` prints nothing; the line 55 claim agrees with `nix eval .#nixosConfigurations.anuramat-bgm5.config.boot.tmp.useTmpfs`.

### E6. uc3/README.md overstates the /run/agenix isolation, has an incomplete Architecture entry, and uses non-ASCII punctuation

**Where:** `home-modules/heavy-linux/agents/uc3/README.md:104`, `home-modules/heavy-linux/agents/uc3/README.md:61`, `home-modules/heavy-linux/agents/uc3/README.md:1`, `home-modules/heavy-linux/agents/sandbox.nix:104`
**Effort:** trivial -- **Risk:** none

**Problem:**

- Lines 104-105 say "None of this is reachable from the sandbox: no `~/.ssh`, no readable `/run/agenix`, and no ControlMaster socket bound in." But sandbox.nix:104-106 binds `config.lib.secrets.tgfy-token.path`, `tgfy-id.path` and `agent.path` read-only; evaluating `agents.sandbox.roDirs` for bgm5 gives /run/agenix/tgfy-token, /run/agenix/tgfy-id and /run/agenix/agent. Only the uc3 secrets are unreachable (the test at line 187, `cat /run/agenix/uc3-totp` fails, is still correct).
- Line 61, `default.nix   # uc3ctl package, the relay's handler, ssh master service, state dir`, omits the `uc3pull` package (uc3/default.nix:31) and the `uc3-status` service and timer (uc3/default.nix:85,97), although the same tree lists uc3pull.sh and status.sh.
- It is the only non-ASCII file under home-modules/heavy-linux/agents/: em dashes on lines 1, 6, 38, 107, 114, 115, 123, 133, 171 and 189, arrows on 129 and 194, and ellipses on 137, 138 and 159, against the plain-ASCII rule.

**Fix:** in home-modules/heavy-linux/agents/uc3/README.md:

- Lines 104-105 -> "None of this is reachable from the sandbox: no `~/.ssh`, no readable uc3 secret under `/run/agenix` (the sandbox binds only `tgfy-*` and `agent` there), and no ControlMaster socket bound in."
- Line 61 -> `default.nix   # uc3ctl and uc3pull packages, the relay's handler, ssh master and uc3-status units, state dir`.
- Replace each em dash with `--`, each arrow (lines 129, 194) with `->` and each ellipsis (137, 138, 159) with `...`.

**Verify:** `grep -nP '[^\x00-\x7F]' home-modules/heavy-linux/agents/uc3/README.md` prints nothing; the line 104-105 wording matches the `config.lib.secrets.*` entries in sandbox.nix's `roDirs`.

### E7. Non-ASCII ellipsis in the fleet-monitor widget

**Where:** `home-modules/heavy-linux/desktop/noctalia/fleet-monitor/widget.luau:89`, `home-modules/heavy-linux/desktop/noctalia/fleet-monitor/widget.luau:91`
**Effort:** trivial -- **Risk:** none

**Problem:** The comment at widget.luau:89 (`-- only clicks get "updating<U+2026>", so frequent polling doesn't flicker`) and the label at :91 (`table.insert(header, label("updating<U+2026>", "outline"))`) use U+2026 (horizontal ellipsis). They are the only non-ASCII characters in home-modules/heavy and home-modules/heavy-linux outside agents/ (the uc3 README is E6), and the user's rules require plain ASCII where possible; `...` is a direct substitute.

**Fix:** replace U+2026 with `...` on widget.luau:89 and :91.

**Verify:** `grep -rnP '[^\x00-\x7F]' home-modules/heavy home-modules/heavy-linux --exclude-dir=agents` prints nothing; clicking a remote section in the fleet monitor shows "updating...".

## F. Refactors: flake, NixOS, Home Manager

### F1. Export the shellcheck excludes once, as `SC`-prefixed strings

**Where:** `home-modules/base/bash/default.nix:9`, `home-modules/base/bash/default.nix:176`, `home-modules/base/bash/default.nix:182`, `home-modules/base/bin/default.nix:13`, `home-modules/heavy-linux/desktop/niri/shortcuts.nix:5`, `home-modules/heavy-linux/agents/uc3/default.nix:8`
**Effort:** trivial -- **Risk:** none

**Problem:** bash/default.nix:9 defines the integer list `shellcheckExcludes = [ 2016 # ... ]` and exports it at :176 as `lib.shellcheck.excludes = shellcheckExcludes;`. Every use needs the `SC`-prefixed string form instead. The shellcheckrc at :182 re-adds the prefix (`concatMapStrings (v: "disable=SC${toString v}\n") shellcheckExcludes`). The only three consumers of `config.lib.shellcheck.excludes`, base/bin/default.nix:13, niri/shortcuts.nix:5 and agents/uc3/default.nix:8, each repeat `excludeShellChecks = map (v: "SC" + toString v) config.lib.shellcheck.excludes;` verbatim, only to pass it on as `inherit excludeShellChecks;` to writeShellApplication. A repo-wide grep finds no other consumer of `lib.shellcheck`. `fzsort` (base/search.nix:94) has its own `excludeShellChecks = [ "SC2016" ];` and agents/job.nix:41 uses an inline `# shellcheck disable=SC2029` directive; both are unaffected. The audit proposed three shapes: convert at the export, convert at the let binding, or have the rc read the converted list back from `config.lib`. The design below needs no conversion at all: the list is written in the form that writeShellApplication, shellcheckrc and search.nix:94 all use already.

**Fix:**
- home-modules/base/bash/default.nix:9-18: rename the let binding `shellcheckExcludes` to `excludeShellChecks` (its element type changes) and write the codes as strings, keeping every per-code comment:
  ```nix
  excludeShellChecks = [
    "SC2016" # expansion in '' won't work
    "SC2059" # don't use variables in printf format string
    "SC2292" # prefer [[]] over []
    "SC2139" # unintended? expansion in an alias (alias a="$test" instead of '$test')
    "SC2250" # use braces even if not necessary
    "SC1003" # trying to escape a single quote?
    "SC2312" # return value is masked by $()
    "SC2154" # referenced but not assigned, e.g. $XDG_CONFIG_HOME
  ];
  ```
- home-modules/base/bash/default.nix:176: `lib.shellcheck.excludeShellChecks = excludeShellChecks;`. The option is renamed from `excludes` because its values change from ints to strings.
- home-modules/base/bash/default.nix:182: `+ lib.strings.concatMapStrings (v: "disable=${v}\n") excludeShellChecks;`
- home-modules/base/bin/default.nix:13, home-modules/heavy-linux/desktop/niri/shortcuts.nix:5, home-modules/heavy-linux/agents/uc3/default.nix:8: replace the `map` line with `inherit (config.lib.shellcheck) excludeShellChecks;`. The `inherit excludeShellChecks;` inside each writeShellApplication call stays, and so does `config` in the three arg lists.
- A13 rewrites shortcuts.nix around a `mkShortcut` helper, and F15 rewrites uc3/default.nix around `mkScript`. Both helpers `inherit ... excludeShellChecks` from the same let, so they work with the new let line and can land in either order.

**Verify:**
- `git grep -nE 'shellcheck\.excludes\b|"SC" \+|SC\$\{toString'` prints nothing.
- The generated scripts and rc are byte-identical. Run this before and after; the output must not change:
  ```sh
  for h in bgm5 f12 t480 root; do nix eval --raw .#nixosConfigurations.anuramat-$h.config.home-manager.users.anuramat.home.activationPackage.drvPath; echo; done
  for h in linux darwin; do nix eval --raw .#homeConfigurations.anuramat-$h.activationPackage.drvPath; echo; done
  ```
  The activation package covers the shellcheckrc, the base/bin scripts, the iOS shortcut scripts and the uc3 relay handler and units.

### F2. Compose the overlays with `lib.composeManyExtensions`

**Where:** `overlays/default.nix:268`, `overlays/default.nix:7`, `overlays/default.nix:108`
**Effort:** small -- **Risk:** low

**Problem:** overlays/default.nix:268-280 hand-rolls overlay composition: `overlays = [ overrides flakes inputs.neovim-nightly-overlay.overlays.default inputs.oh-my-pi.overlays.default ];` followed by `final: prev: let unwrapped = map (x: x final prev) overlays; merge = lib.foldr (a: b: a // b) { }; in merge unwrapped`. That is `lib.composeManyExtensions` with weaker semantics: every overlay sees the same `prev` and the results are merged last-wins. The difference does not matter here, because the four overlays define disjoint names. The third-party ones only set `neovim`, `neovim-debug`, `neovim-developer`, `neovim-unwrapped` and `oh-my-pi`, and both build from `final` (flake-parts easyOverlay and `final.callPackage`), so they don't depend on what `prev` contains. The git history (7bace88c and earlier) gives no reason for the hand-rolled merge. Two nits in the same file: `inherit (builtins) mapAttrs ;` (lines 7-9) exists for a single use at line 13, and line 108 writes `prev.lib.cmakeBool` although `lib` is in scope; both are the same nixpkgs functions.

Checked on a scratch copy with the change applied, against nixpkgs x86_64-linux: the drvPaths of sem, vicode, nil, statix, ghostty, claude-code, codex, kitty, yazi-unwrapped, yazi, darktable, proton-drive-cli, nirimap, caut, todo, zotero-mcp, neovim, neovim-unwrapped, oh-my-pi, zellij, firefox, llama-cpp-vulkan, rocmPackages.clr and vimPlugins.{tinted-nvim, rustaceanvim, figtree-nvim, wastebin-nvim, tree-climber-rust-nvim, nvim-treesitter} were identical before and after, as were bgm5's `config.system.path`, its `home-manager.users.anuramat.home.path` and `packages.x86_64-linux.neovim`.

**Fix:**
- Replace lines 268-280 (`overlays = [ ... ];` through `merge unwrapped`) with:
  ```nix
  in
  lib.composeManyExtensions [
    overrides
    flakes
    inputs.neovim-nightly-overlay.overlays.default
    inputs.oh-my-pi.overlays.default
  ]
  ```
- Delete lines 7-9 (`inherit (builtins) mapAttrs ;`) and write `(lib.mapAttrs (_: v: ...` at line 13.
- Line 108: `prev.lib.cmakeBool` -> `lib.cmakeBool`.

**Verify:** These print the same before and after, and `nix flake check` passes:
```sh
B=.#nixosConfigurations.anuramat-bgm5
nix eval --raw $B.config.system.path.drvPath; echo
nix eval --raw $B.config.home-manager.users.anuramat.home.path.drvPath; echo
nix eval --raw .#packages.x86_64-linux.neovim.drvPath; echo
nix eval --json $B.pkgs --apply 'p: map (n: p.${n}.drvPath) [ "darktable" "ghostty" "llama-cpp-vulkan" "neovim-unwrapped" "oh-my-pi" "yazi" ]'
```

### F3. Get noctalia and ctrlsn from the overlay's `flakes` list

**Where:** `overlays/default.nix:11`, `home-modules/heavy-linux/desktop/noctalia/default.nix:25`, `nixos-configurations/anuramat-root/web/index.nix:13`
**Effort:** trivial -- **Risk:** low

**Problem:** The overlay's `flakes` maps `inputs.X.packages.${prev.stdenv.hostPlatform.system}.default` to `pkgs.X` for 16 inputs, but two sites repeat that lookup inline: noctalia/default.nix:25 `package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (...)` and index.nix:13 `binary = "${inputs.ctrlsn.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ctrl.sn";`. The pinned nixpkgs has no `noctalia` or `ctrlsn` attribute (only `noctalia-qs` and `noctalia-shell` under by-name), and the overlay's unstable inherits don't include them, so adding them shadows nothing. The lookups are lazy, so non-Linux systems are unaffected. ctrlsn's `meta.mainProgram` evaluates to "ctrl.sn".

**Fix:**
- overlays/default.nix: add `noctalia` and `ctrlsn` to the `inherit (inputs) ...` list in `flakes`. This composes with F2, which only changes the `mapAttrs` call around that list.
- home-modules/heavy-linux/desktop/noctalia/default.nix:25: `package = pkgs.noctalia.overrideAttrs (old: { ... });`, with the body and the comments above unchanged. Keep the `inputs` arg; it is still needed for `inputs.noctalia.homeModules.default` at :13.
- nixos-configurations/anuramat-root/web/index.nix: change the args to `{ lib, pkgs, ... }:` and set `binary = lib.getExe pkgs.ctrlsn;`. This also removes the hand-built `/bin/ctrl.sn` path, so F6 leaves this file out.

**Verify:** Both print the same before and after:
```sh
nix eval --json .#nixosConfigurations.anuramat-root.config.web.sites --apply 'map (w: w.binary)'
nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat.programs.noctalia.package.drvPath
```

### F4. Drop the shfmt flags that treefmt-nix already passes

**Where:** `parts/treefmt.nix:5`
**Effort:** trivial -- **Risk:** none

**Problem:** parts/treefmt.nix:4-9 sets `shfmt.options = [ "--write" "--simplify" "--case-indent" "--binary-next-line" ];`, but treefmt-nix's programs/shfmt.nix already registers `args = [ "-s" "-w" ]`. The lists merge, so the generated treefmt.toml has `options = ["-s", "-w", "--write", "--simplify", "--case-indent", "--binary-next-line", "-i", "0"]`, with write and simplify each passed twice. The similar list in nixvim-modules/heavy/lang/misc.nix:50-53 is a raw treefmt.toml template for other projects, with no treefmt-nix defaults behind it, so it must keep its flags.

**Fix:** In parts/treefmt.nix, set `shfmt.options = [ "--case-indent" "--binary-next-line" ];`. Leave nixvim-modules/heavy/lang/misc.nix as is.

**Verify:** The formatter's config lists the shfmt options `-s -w --case-indent --binary-next-line -i 0`, and `nix fmt` produces no diff:
```sh
grep -ao '/nix/store/[^ "]*treefmt.toml' "$(nix build --no-link --print-out-paths .#formatter.x86_64-linux)/bin/treefmt" | head -1 | xargs grep -A12 'formatter.shfmt'
```

### F5. Write the binary-cache key path once

**Where:** `nixos-modules/base/nix.nix:41`, `nixos-modules/base/nix.nix:88`, `home-modules/base/bin/default.nix:33`
**Effort:** trivial -- **Risk:** none

**Problem:** nix.nix writes "/etc/nix/cache.pem" twice: `secret-key-files = "/etc/nix/cache.pem";` (:41) and `signKeyPaths = [ "/etc/nix/cache.pem" ];` (:88). nix-cache-keygen already reads `private = osConfig.nix.settings.secret-key-files;` (bin/default.nix:32), but hardcodes `public = "/etc/nix/cache.pem.pub";` at :33. Evaluated on f12, `secret-key-files` is the plain string "/etc/nix/cache.pem", so `[ config.nix.settings.secret-key-files ]` gives the same list. The literal "/etc/nix/cache.pem.pub" in the justfile's `nixos-pre` recipe (justfile:16) must stay, because it can't read Nix.

**Fix:**
- nixos-modules/base/nix.nix:88: `signKeyPaths = [ config.nix.settings.secret-key-files ];`
- home-modules/base/bin/default.nix:33: `public = "${private}.pub";`. Keep the `# TODO move and read public` comment above it unless the user confirms this is what it meant.
- H1 (needs a decision) may move nix-cache-keygen into a NixOS module. If it does, apply the bin/default.nix half there instead.

**Verify:** `nix eval --json .#nixosConfigurations.anuramat-f12.config.services.harmonia.cache.signKeyPaths` still prints `["/etc/nix/cache.pem"]`, and `nix eval --raw .#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat.home.path.drvPath` is unchanged (it contains nix-cache-keygen).

### F6. Use `lib.getExe` / `getExe'` instead of hand-built `/bin` paths

**Where:** `home-modules/heavy-linux/agents/uc3/default.nix:79`, `home-modules/heavy-linux/agents/uc3/default.nix:89`, `home-modules/heavy-linux/desktop/niri/keys.nix:11`, `home-modules/heavy-linux/desktop/niri/keys.nix:54`, `home-modules/heavy-linux/desktop/niri/keys.nix:66`, `home-modules/heavy-linux/desktop/niri/keys.nix:121`, `nixos-configurations/anuramat-bgm5/power.nix:3`, `nixos-configurations/anuramat-bgm5/power.nix:4`, `nixos-modules/base/net.nix:37`
**Effort:** small -- **Risk:** none

**Problem:** About 60 lines in the repo use `getExe`/`getExe'`, but `git grep -nE '\}/bin/[a-zA-Z]'` still finds hand-built paths: `"${pkgs.openssh}/bin/ssh -o ConnectTimeout=15 -fN uc3"` (uc3:79) and `"${status}/bin/uc3-status"` (uc3:89), in a file whose line 64 already uses `lib.getExe handler`; `"${pkgs.tlp}/bin/bluetooth"` and `"${pkgs.tlp}/bin/wifi"` (keys.nix:54, :66) and `pkill = "${pkgs.procps}/bin/pkill";` (keys.nix:121), in a file that otherwise uses `getExe`; `ryzenadj = "${pkgs.ryzenadj}/bin/ryzenadj";` and `awk = "${pkgs.gawk}/bin/awk";` (power.nix:3-4); and `script = "${pkgs.vpn-slice}/bin/vpn-slice ..."` (net.nix:37). Evaluated `meta.mainProgram` values: openssh = ssh, ryzenadj = ryzenadj, vpn-slice = vpn-slice; gawk = gawk, tlp = tlp and procps = null, so those three need `getExe'`; writeShellApplication sets `mainProgram` to its `name`, so `status` gives uc3-status. Every replacement yields the same string. The remaining hits are handled elsewhere: index.nix:13 by F3; home-modules/linux.nix:36/38 (the pinentry wrapper) by C9, which removes the same redundancy from the other side (it drops `runtimeInputs` and keeps the absolute paths), so don't also rewrite those lines here; uc3:76 is a profile path (`${config.home.profileDirectory}/bin/uc3-askpass`), not a package, and stays.

**Fix:**
- home-modules/heavy-linux/agents/uc3/default.nix:79: `ExecStart = "${lib.getExe pkgs.openssh} -o ConnectTimeout=15 -fN uc3";`
- home-modules/heavy-linux/agents/uc3/default.nix:89: `ExecStart = lib.getExe status;`
- home-modules/heavy-linux/desktop/niri/keys.nix:11: `inherit (lib) escapeShellArg getExe getExe';`
- keys.nix:54 and :66: `(getExe' pkgs.tlp "bluetooth")` and `(getExe' pkgs.tlp "wifi")`.
- keys.nix:121: `pkill = getExe' pkgs.procps "pkill";`
- nixos-configurations/anuramat-bgm5/power.nix: change the args to `{ lib, pkgs, ... }:`, then `ryzenadj = lib.getExe pkgs.ryzenadj;` and `awk = lib.getExe' pkgs.gawk "awk";`.
- nixos-modules/base/net.nix:37 (`lib` is already an arg): `script = "${lib.getExe pkgs.vpn-slice} --no-host-names --no-ns-hosts bwunicluster.scc.kit.edu 129.206.0.0/16 147.142.0.0/16";`

**Verify:** All of these print the same before and after. Comparing `system.build.toplevel.drvPath` does not work for the NixOS parts: `nix.registry` and `nix.nixPath` contain `inputs.self`, so any source edit changes the toplevel.
```sh
nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat.home.activationPackage.drvPath; echo
nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.system.path.drvPath; echo
nix eval --raw .#nixosConfigurations.anuramat-f12.config.networking.openconnect.interfaces.uhd.extraOptions.script; echo
```
The first covers the uc3 units and the niri binds; the second covers `bgm5powerctl`, which power.nix adds to `environment.systemPackages`.

### F7. Use `lib.optional` / `optionals` / `optionalAttrs` instead of hand-written conditionals

**Where:** `home-modules/base/bin/default.nix:52`, `home-modules/base/editor.nix:24`, `home-modules/heavy-linux/agents/sandbox.nix:42`, `home-modules/heavy-linux/agents/sandbox.nix:153`, `nixos-modules/laptop/keyboard.nix:3`
**Effort:** trivial -- **Risk:** none

**Problem:** The repo uses `lib.optional*` elsewhere, but five sites spell them out: `packages ++ (if osConfig != null then [ nix-cache-keygen ] else [ ])` (bin/default.nix:52); `// (if osConfig == null then { } else { inherit osConfig; })` (editor.nix:24, inside a block marked `# SLOP`); `++ (if doublePath then [ x ] else [ ])` (sandbox.nix:42); `agentDirs = if agentDir != null then (map ...) else [ ];` (sandbox.nix:153-162); and `warnings = if config.services.keyd.keyboards.main.ids == [ ] then [ "no keyboard specified ..." ] else [ ];` (keyboard.nix:3-9). `lib` is already an arg in every file, and each rewrite is semantically identical.

**Fix:**
- home-modules/base/bin/default.nix:52: `home.packages = packages ++ lib.optional (osConfig != null) nix-cache-keygen;`. If H1 moves the script out of Home Manager, this line becomes `home.packages = packages;` instead.
- home-modules/base/editor.nix:24: `// lib.optionalAttrs (osConfig != null) { inherit osConfig; };`
- home-modules/heavy-linux/agents/sandbox.nix:42: `++ lib.optional doublePath x`
- sandbox.nix:153-162: `agentDirs = lib.optionals (agentDir != null) (map (v: "${v}/${agentDir}") [ config.xdg.cacheHome config.xdg.configHome config.xdg.dataHome config.xdg.stateHome ]);`. F16 makes `agentDir` default to null; this rewrite is the same either way.
- nixos-modules/laptop/keyboard.nix:3-9: `warnings = lib.optional (config.services.keyd.keyboards.main.ids == [ ]) "no keyboard specified for keyd, remaps will not be applied";` (nixfmt may wrap it).

**Verify:** These print the same before and after; the standalone configs exercise the `osConfig == null` branches:
```sh
nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat.home.activationPackage.drvPath; echo
for h in linux darwin; do nix eval --raw .#homeConfigurations.anuramat-$h.activationPackage.drvPath; echo; done
for h in f12 t480; do nix eval --json .#nixosConfigurations.anuramat-$h.config.warnings; done
```
The last loop must still print `[]` twice.

### F8. Drop the needless `with lib` / `with lib.attrsets` scopes

**Where:** `nixos-modules/local/rice.nix:21`, `nixos-modules/base/nix.nix:29`, `nixos-modules/base/nix.nix:35`, `nixos-modules/base/nix.nix:37`
**Effort:** trivial -- **Risk:** none

**Problem:** rice.nix:21-24 opens `services.getty = with lib; { ... };` only for two `mkForce` calls. nix.nix:29 opens `nix = with lib.attrsets; {` only for `mapAttrs` (:35) and `mapAttrsToList` (:37), while :67 in the same attrset already writes `lib.mapAttrsToList`. :35 also holds the only deadnix hit in nixos-modules: `mapAttrs (n: v: { flake = v; })`, where `n` is unused (`just lint` runs `deadnix -l`, which skips lambda arguments, so it doesn't show there).

**Fix:**
- nixos-modules/local/rice.nix:21-24:
  ```nix
  services.getty = {
    greetingLine = lib.mkForce ''\l'';
    helpLine = lib.mkForce "";
  };
  ```
- nixos-modules/base/nix.nix:29: `nix = {`
- nix.nix:35: `registry = lib.mapAttrs (_: flake: { inherit flake; }) inputs;`
- nix.nix:37: `nixPath = lib.mapAttrsToList (n: v: "${n}=${v.outPath}") inputs;`

**Verify:** `nix run nixpkgs#deadnix -- nixos-modules` prints nothing (today it reports `nix.nix:35:26 Unused lambda argument: n`). `nix eval --json .#nixosConfigurations.anuramat-f12.config.services.getty --apply 'g: { inherit (g) greetingLine helpLine; }'` and `nix eval --json .#nixosConfigurations.anuramat-f12.config.nix.registry --apply builtins.attrNames` are unchanged, and `nix flake check` passes. (Comparing toplevel drvPaths does not work, see F6.)

### F9. web.nix: collapse the complementary root/subdomain branches

**Where:** `nixos-modules/base/web.nix:34`, `nixos-modules/base/web.nix:69`, `nixos-modules/base/web.nix:101`
**Effort:** small -- **Risk:** low

**Problem:** `vhostsFor` builds the main vhost from two list elements: `{ ${w.domain}.locations."/".proxyPass = ...; }` and `if w.root == w.domain then { ${w.domain} = { enableACME = true; forceSSL = true; default = true; }; } else { ${w.domain} = { useACMEHost = w.root; forceSSL = true; }; }`, which repeats `forceSSL = true` in both branches. `acmeCertsFor` is `optional (w.root != w.domain) { ... } ++ optional (w.root == w.domain) { ... }`: two complementary optionals that always yield exactly one attrset. Checked in a scratch copy: setting `enableACME = false`, `default = false` and `useACMEHost = null` explicitly for subdomains equals the option defaults, and the resulting nginx vhosts and ACME certs are unchanged.

**Fix:** In nixos-modules/base/web.nix:
- Rewrite `vhostsFor` (keep the robots and www elements' bodies as they are):
  ```nix
  vhostsFor =
    w:
    let
      isRoot = w.root == w.domain;
    in
    [
      {
        ${w.domain} = {
          locations."/".proxyPass = "http://localhost:${w.port}";
          forceSSL = true;
          enableACME = isRoot;
          default = isRoot;
          useACMEHost = if isRoot then null else w.root;
        };
      }
    ]
    ++ optional w.noRobots { ... } # unchanged
    ++ optional isRoot { "www.${w.domain}" = { ... }; }; # unchanged
  ```
- Replace `acmeCertsFor` with `acmeCertFor = w: { ${w.root}.extraDomainNames = [ (if w.root == w.domain then "www.${w.domain}" else w.domain) ]; };`. It is renamed because it now returns one attrset instead of a list.
- Line 101: `security.acme.certs = mkMerge (map acmeCertFor config.web.sites);`

**Verify:** These print the same before and after (today: `{"ctrl.sn":["www.ctrl.sn","bin.ctrl.sn"]}` and the three vhosts ctrl.sn, www.ctrl.sn and bin.ctrl.sn):
```sh
R=.#nixosConfigurations.anuramat-root.config
nix eval --json $R.security.acme.certs --apply 'builtins.mapAttrs (_: c: c.extraDomainNames)'
nix eval --json $R.services.nginx.virtualHosts --apply 'builtins.mapAttrs (_: v: { inherit (v) enableACME useACMEHost default forceSSL globalRedirect; proxy = builtins.mapAttrs (_: l: l.proxyPass) v.locations; })'
```

### F10. Generate the 27 per-workspace niri binds

**Where:** `home-modules/heavy-linux/desktop/niri/keys.nix:221`
**Effort:** trivial -- **Risk:** none

**Problem:** keys.nix:221-249 writes out the same three binds for workspaces 1-9 by hand: `"Mod+1".action.focus-workspace = 1;` ... `"Mod+9"...`, then the matching `"Mod+Ctrl+N".action.move-window-to-workspace = N;` and `"Mod+Shift+N".action.move-column-to-workspace = N;` blocks, 27 lines in total. The generated form below evaluates to exactly these 27 attrs with the pinned nixpkgs lib. The full binds set has 94 entries today.

**Fix:** Delete lines 221-249 and append the generated binds after the closing `}` of `programs.niri.settings.binds = { ... }` (line 263); `lib` is already an arg:
```nix
  programs.niri.settings.binds = {
    # ...
  }
  // lib.mergeAttrsList (
    map (
      i:
      let
        n = toString i;
      in
      {
        "Mod+${n}".action.focus-workspace = i;
        "Mod+Ctrl+${n}".action.move-window-to-workspace = i;
        "Mod+Shift+${n}".action.move-column-to-workspace = i;
      }
    ) (lib.range 1 9)
  );
```
Run `nix fmt` afterwards.

**Verify:** With `H=.#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat`, `nix eval --json $H.programs.niri.settings.binds | sha256sum` is identical before and after.

### F11. Merge the split ghostty config into gui/terminals.nix

**Where:** `home-modules/heavy-linux/terminals.nix:1`, `home-modules/heavy-linux/gui/terminals.nix:6`, `home-modules/heavy-linux/default.nix:14`
**Effort:** small -- **Risk:** none

**Problem:** home-modules/heavy-linux/terminals.nix is a leftover of the foot config (b01d194f, then e5b99a01 replaced foot with ghostty). It now holds two `programs.ghostty.settings` keys (`command = "bash -l"; window-decoration = "false";`), `TERMCMD = "${lib.getExe config.programs.ghostty.package}";` (a needless interpolation of a string) with a commented-out kitty alternative, and `NIXOS_OZONE_WL = "1"; # wayland chromium/electron`, which has nothing to do with terminals. The rest of `programs.ghostty` lives in heavy-linux/gui/terminals.nix, in the same layer. Both files are imported unconditionally, so merging them cannot change behavior. TERMCMD is read via `config.home.sessionVariables.TERMCMD` (niri/keys.nix:73, portals.nix:23), which stays valid.

**Fix:**
- home-modules/heavy-linux/gui/terminals.nix: change the args to `{ config, lib, pkgs, ... }:`. Add `command = "bash -l";` and `window-decoration = "false";` to `programs.ghostty.settings`. Add `home.sessionVariables.TERMCMD = lib.getExe config.programs.ghostty.package;` followed by the existing `# TERMCMD = "${lib.getExe pkgs.kitty} -1";` comment.
- home-modules/heavy-linux/gui/default.nix: add `home.sessionVariables.NIXOS_OZONE_WL = "1"; # wayland chromium/electron`.
- Delete home-modules/heavy-linux/terminals.nix and its `./terminals.nix` import at heavy-linux/default.nix:14. F12 also edits that imports list; the two are independent.

**Verify:** With `H=.#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat`, `nix eval --raw "$H.xdg.configFile.\"ghostty/config\".text"` and `nix eval --json $H.home.sessionVariables` print the same before and after.

### F12. Move the swayimg config and the spicetify import into heavy-linux/gui

**Where:** `home-modules/heavy-linux/default.nix:15`, `home-modules/heavy-linux/default.nix:32`, `home-modules/heavy-linux/default.nix:55`, `home-modules/heavy-linux/gui/default.nix:21`
**Effort:** small -- **Risk:** none

**Problem:** AGENTS.md puts "Linux-only graphical apps in `heavy-linux/gui`", but the swayimg viewer's `xdg.configFile."swayimg/init.lua".text` (heavy-linux/default.nix:32-53) and `home.packages = with pkgs; [ swayimg ];` (:55-57) live in heavy-linux/default.nix rather than in gui/viewers.nix next to zathura and mpv. Also, `inputs.spicetify-nix.homeManagerModules.spicetify` is imported at heavy-linux/default.nix:15, while `programs.spicetify` is configured only in gui/default.nix:21-32; elsewhere the upstream module is imported next to its use (noctalia/default.nix:13). gui/ is imported unconditionally, so both moves preserve behavior. Afterwards, `lib` and `inputs` are unused in heavy-linux/default.nix.

**Fix:**
- Move the `# https://github.com/artemsen/swayimg/blob/master/CONFIG.md` comment, the `xdg.configFile."swayimg/init.lua".text = ...` block and the swayimg package (as `home.packages = [ pkgs.swayimg ];`) from home-modules/heavy-linux/default.nix:32-57 into home-modules/heavy-linux/gui/viewers.nix, whose args become `{ lib, pkgs, ... }:` (it has none today).
- Move `inputs.spicetify-nix.homeManagerModules.spicetify` from heavy-linux/default.nix:15 into the `imports` list of heavy-linux/gui/default.nix.
- Shrink heavy-linux/default.nix's args to `{ pkgs, ... }:`.
- Leave heavy-linux/packages.nix as it is; regrouping its GUI apps would be a matter of taste.

**Verify:** With `H=.#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat`, `nix eval --raw "$H.xdg.configFile.\"swayimg/init.lua\".text"` and `nix eval --json $H.home.packages --apply 'ps: builtins.sort builtins.lessThan (map (p: p.name) ps)'` print the same before and after (the package order changes, so compare the sorted names rather than drvPaths), and `nix flake check` passes.

### F13. autologin: drop the `wm` alias and the always-true `command -v`

**Where:** `home-modules/heavy-linux/desktop/niri/autologin.nix:19`, `home-modules/heavy-linux/desktop/niri/autologin.nix:29`
**Effort:** trivial -- **Risk:** low

**Problem:** autologin.nix:19 `wm = niri;` only renames a binding. The profile test `&& command -v ${wm} >/dev/null 2>&1` (:29) checks an absolute store path that the generated profile itself references, so the path is in the closure and the test is always true. Lines 27-31 also start with literal tab characters after the 8-space Nix indent (`cat -A` shows `^I`), so the tabs end up in the rendered profile.

**Fix:** In home-modules/heavy-linux/desktop/niri/autologin.nix, delete `wm = niri;` and the blank line before it, and replace the profileExtra string with a space-indented one:
```nix
    profileExtra =
      # bash
      ''
        if [[ -z $WAYLAND_DISPLAY && $XDG_VTNR == 1 ]]; then
          exec ${niri}
        fi
      '';
```
Keep the `# auto start on 1st tty` comment and the `niri` script with its TODO comments unchanged.

**Verify:** With `H=.#nixosConfigurations.anuramat-f12.config.home-manager.users.anuramat`, `nix eval --raw $H.programs.bash.profileExtra` shows the simplified block with no tabs. After a switch, logging in on tty1 still starts niri, and logging in on another tty does not.

### F14. Drop a needless string interpolation and a single-use let

**Where:** `home-modules/heavy-linux/gui/default.nix:96`, `home-modules/heavy-linux/desktop/portals.nix:42`
**Effort:** trivial -- **Risk:** none

**Problem:** gui/default.nix:96 writes `text_font = "${config.stylix.fonts.serif.name}";`, an interpolation of a string into a string. portals.nix:42-53 writes `config = let portalConfig = { ... }; in { common = portalConfig; };`, binding `portalConfig` only to use it once. (The hand-built tlp and procps paths in niri/keys.nix that were reported together with these are in F6.)

**Fix:**
- home-modules/heavy-linux/gui/default.nix:96: `text_font = config.stylix.fonts.serif.name;`
- home-modules/heavy-linux/desktop/portals.nix:42-53:
  ```nix
  config.common = {
    "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
    "org.freedesktop.impl.portal.ScreenCast" = "wlr";
    "org.freedesktop.impl.portal.Screenshot" = "wlr";
    default = "gtk";
  };
  ```

**Verify:** With `H=.#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat`, `nix eval --raw "$H.xdg.configFile.\"swappy/config\".text"` and `nix eval --json $H.xdg.portal.config` print the same before and after.

### F15. uc3: build the four scripts with one local helper

**Where:** `home-modules/heavy-linux/agents/uc3/default.nix:10`, `home-modules/heavy-linux/agents/uc3/default.nix:21`, `home-modules/heavy-linux/agents/uc3/default.nix:31`, `home-modules/heavy-linux/agents/uc3/default.nix:44`
**Effort:** small -- **Risk:** low

**Problem:** uc3/default.nix:10-52 builds `handler`, `uc3ctl`, `uc3pull` and `status` with four writeShellApplication blocks of the same shape, `{ name = ...; runtimeInputs = ...; inherit excludeShellChecks; text = builtins.readFile ./X.sh; }`, which differ only in name, file and inputs. The names can't be derived from the file names (handler.sh -> uc3-handler, shim.sh -> uc3ctl), so a three-argument helper is the minimal form. Checked in a scratch copy (formatted with nixfmt): the file shrinks from 106 to 97 lines, and the HM drvPaths on all hosts were identical when gnugrep was left out.

**Fix:** In home-modules/heavy-linux/agents/uc3/default.nix, add this after the `excludeShellChecks` let line (which F1 turns into `inherit (config.lib.shellcheck) excludeShellChecks;`) and replace the four blocks:
```nix
  mkScript =
    name: file: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs excludeShellChecks;
      text = builtins.readFile file;
    };

  handler = mkScript "uc3-handler" ./handler.sh (with pkgs; [ coreutils openssh systemd ]);
  uc3ctl = mkScript "uc3ctl" ./shim.sh [ pkgs.coreutils config.lib.agents.relayClient ];
  uc3pull = mkScript "uc3pull" ./uc3pull.sh (with pkgs; [ coreutils croc diffutils findutils uc3ctl ]);
  status = mkScript "uc3-status" ./status.sh [ pkgs.coreutils uc3ctl ];
```
Carry each `runtimeInputs` list over as it is at the time: once A11 is applied, the handler's list is `[ coreutils gnugrep openssh systemd ]`. Run `nix fmt` afterwards. F6's `ExecStart = lib.getExe status;` is unaffected, since the binding keeps its name.

**Verify:** Applied on its own (with no change to any `runtimeInputs`), `nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat.home.activationPackage.drvPath` is unchanged, and `nix flake check` passes.

### F16. mkPackages: drop the redundant `binName` arg and default `agentDir` to null

**Where:** `home-modules/heavy-linux/agents/sandbox.nix:117`, `home-modules/heavy-linux/agents/sandbox.nix:118`, `home-modules/heavy-linux/agents/sandbox.nix:121`, `home-modules/heavy-linux/agents/sandbox.nix:253`, `home-modules/heavy-linux/agents/frontends/codex.nix:117`, `home-modules/heavy-linux/agents/frontends/codex.nix:121`, `home-modules/heavy-linux/agents/frontends/omp.nix:17`, `home-modules/heavy-linux/agents/frontends/omp.nix:21`
**Effort:** trivial -- **Risk:** low

**Problem:** `binName ? package.meta.mainProgram` (sandbox.nix:117) is overridden only as `binName = "codex";` (codex.nix:117) and `binName = "omp";` (omp.nix:17), and both equal the default: evaluated on bgm5, `codex.meta.mainProgram` = "codex", `oh-my-pi.meta.mainProgram` = "omp" and `claude-code.meta.mainProgram` = "claude". binName is used only in `wrapperName ? binName` (:118) and in `rm -f "$out/bin/${binName}"` (:253). An override that differed from mainProgram would be wrong anyway, because `cmd` always runs `getExe package`. Separately, `agentDir` (:121) is a required arg, yet codex.nix:121 and omp.nix:21 pass `agentDir = null;`; only claude.nix passes "claude". Checked in a scratch copy: the home.path and activationPackage drvPaths were identical on all hosts and both standalone configs, and the built codex-wrappers and oh-my-pi-wrappers still have the original binary replaced by the sandbox wrapper.

**Fix:**
- home-modules/heavy-linux/agents/sandbox.nix: delete `binName ? package.meta.mainProgram,` (:117), change :118 to `wrapperName ? package.meta.mainProgram,` and :121 to `agentDir ? null, # name of subdir in xdg dirs`. In postBuild (:253), use `rm -f "$out/bin/${package.meta.mainProgram}"`.
- frontends/codex.nix: delete `binName = "codex";` (:117) and `agentDir = null;` (:121).
- frontends/omp.nix: delete `binName = "omp";` (:17) and `agentDir = null;` (:21).
- The `if agentDir != null then ... else [ ]` in `agentDirs` becomes `lib.optionals` in F7.

**Verify:** With `H=.#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat`, `nix eval --raw $H.home.path.drvPath` and `nix eval --raw $H.home.activationPackage.drvPath` are unchanged, and `nix flake check` passes.

### F17. sandbox.nix: emit the wrapper env with Home Manager's `exportAll`

**Where:** `home-modules/heavy-linux/agents/sandbox.nix:13`, `home-modules/heavy-linux/agents/sandbox.nix:17`, `home-modules/heavy-linux/agents/sandbox.nix:134`, `home-modules/heavy-linux/agents/frontends/claude.nix:85`
**Effort:** trivial -- **Risk:** low

**Problem:** `exportScript` (sandbox.nix:17-26) emits `${n}=${v}` followed by `export ${n}` for every variable in a wrapper's `env`. The value is unquoted, so one with spaces would be word-split, and `${v}` fails at eval for non-strings, such as the commented-out `CLAUDE_CODE_AUTO_COMPACT_WINDOW = 400000;` at claude.nix:85. The assign-then-export split copies mkAgenixExportScript, which needs it for `$(<file)` (SC2155), but literal values don't, and the binding uses `builtins.concatStringsSep` while the rest of the file uses lib. Home Manager already provides the helper: `config.lib.shell.exportAll` (HM modules/lib/shell.nix) emits `export N="value"` for each variable, converting bools with `boolToString` and everything else with `toString`, and skips nulls; HM uses it itself for `home.sessionVariables`. Double quotes keep `$VAR` expansion, which the current unquoted assignment also does. That matters because codex.nix:129 and omp.nix:32 also assign the same `env` attrsets to `home.sessionVariables`. The original proposal, `lib.escapeShellArg`, would single-quote the values and turn off that expansion, so don't use it. Checked in a scratch copy: codex-wrappers, claude-code-wrappers and oh-my-pi-wrappers build (so writeShellApplication's shellcheck passes), bin/codex contains `export CODEX_HOME="/home/anuramat/.config/codex"` and bin/claude-zai contains `export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"`.

**Fix:** In home-modules/heavy-linux/agents/sandbox.nix:
- Delete the `exportScript` binding (lines 17-26).
- Line 134, inside `scriptCommon`: `${exportScript env}` -> `${config.lib.shell.exportAll env}`. D15 renames `scriptCommon` to `preamble`; the two changes are independent.
- Remove `mapAttrsToList` from the `inherit (lib) ...` list (line 13). It is unused afterwards, since `sshConfig` writes `lib.mapAttrsToList` explicitly (:55); `deadnix -l` reports it otherwise.

**Verify:** The wrapper drvs change (the quoting changes), so build one and inspect it, then run `nix flake check`:
```sh
drv=$(nix eval --raw .#nixosConfigurations.anuramat-bgm5.config.home-manager.users.anuramat.home.packages --apply 'ps: (builtins.head (builtins.filter (p: p.name == "codex-wrappers") ps)).drvPath')
out=$(nix build --no-link --print-out-paths "$drv^*")
grep -n 'export CODEX_HOME' "$out/bin/codex"
```
The grep prints `export CODEX_HOME="/home/anuramat/.config/codex"`.

## G. Refactors: nixvim

### G1. Move the `just` language settings from heavy/misc.nix into heavy/lang/misc.nix

**Where:** `nixvim-modules/heavy/misc.nix:16-22`, `nixvim-modules/heavy/misc.nix:30`, `nixvim-modules/heavy/lang/misc.nix:8-10`, `nixvim-modules/heavy/lang/misc.nix:81-84`
**Effort:** trivial -- **Risk:** none

**Problem:** Every other per-language setting (ftplugin, formatter, linter) lives under `nixvim-modules/heavy/lang/`; a grep over `heavy/*.nix` and `base/*.nix` finds `just` as the only `mkVimFiles` or `formatters_by_ft` entry outside it. `heavy/lang/misc.nix` collects the minor languages and already has its own `config.lib.mkVimFiles` call and `conform-nvim` block, yet `heavy/misc.nix` still holds `inherit (config.lib.mkVimFiles { just.ftp.ts = 4; }) files extraFiles;` and `conform-nvim.settings.formatters_by_ft.just = [ "just" ];`, so there are two `mkVimFiles` call sites for no reason.

**Fix:**
- In `nixvim-modules/heavy/lang/misc.nix`, add `just.ftp.ts = 4;` to the `mkVimFiles` spec, next to `toml.snippets` (line 10), and change the `conform-nvim` block to:
  ```nix
      conform-nvim = {
        autoInstall.overrides.bake = pkgs.mbake;
        settings.formatters_by_ft = {
          make = [ "bake" ];
          just = [ "just" ];
        };
      };
  ```
- In `nixvim-modules/heavy/misc.nix`, delete lines 16-22 (the `mkVimFiles` inherit) and line 30 (`conform-nvim.settings.formatters_by_ft.just`). `config` stays in use there (`inherit (config.lib) luaf keymap;`).
- B14 and G3 also edit `heavy/misc.nix`; apply them by content, since line numbers shift.

**Verify:**
- Checked in a scratch copy: the `files`/`extraFiles` names and contents and the generated conform `just = { "just" }` are identical after the move.
- Before and after, `nix eval --raw '.#packages.x86_64-linux.neovim.config.files."after/ftplugin/just.lua".content'` prints the same ftplugin (`local nixvim_local_options = { ts = 4 }`), and `nix eval --raw .#packages.x86_64-linux.neovim.config.content` is byte-identical (`diff` the two outputs).
- `grep -n just nixvim-modules/heavy/misc.nix` prints nothing; `just lint` passes.

### G2. copilot `should_attach`: use the `bufname` argument instead of re-reading buffer 0

**Where:** `nixvim-modules/heavy/completion.nix:22-31`, `nixvim-modules/heavy/completion.nix:72`
**Effort:** trivial -- **Risk:** low

**Problem:** The callback is `shouldEnableFunc = ''function() local bufname = vim.api.nvim_buf_get_name(0) ... end'';`. copilot.lua 2.0.4 calls it as `config.should_attach(bufnr, bufname)` for an explicit buffer (`lua/copilot/util.lua:46-64`, reached from `client/init.lua:82` and `command.lua:38`). The callback ignores both arguments and reads the current buffer instead, which is extra code and gives the wrong answer whenever `bufnr` is not the current buffer. Reproduced with the built `neovim`: `nvim --headless -c 'badd /etc/nixos/flake.nix' -c 'lua io.stdout:write(tostring(require("copilot.util").should_attach(vim.fn.bufnr("/etc/nixos/flake.nix"))), "\n")' -c 'qa!'` prints `false`, although `/etc/nixos` paths are meant to attach. The closing `end` is also misindented, and the binding name does not match the option it feeds (`should_attach`).

**Fix:** In `nixvim-modules/heavy/completion.nix`, rename the binding and take the arguments, keeping the `NOTE` comment, the three `string.match` checks and `return false`:
```nix
  # NOTE: calls back home even when disabled
  shouldAttach = # lua
    ''
      function(_, bufname)
        if string.match(bufname, "notes") then return false end
        if string.match(bufname, "%.local/share/ghq") then return true end
        if string.match(bufname, "/etc/nixos") then return true end
        return false
      end
    '';
```
On line 72, use `should_attach = lua shouldAttach;`. C10 edits the same file.

**Verify:**
- `nix build .#checks.x86_64-linux.neovim`.
- `nix run .#neovim -- --headless -c 'badd /etc/nixos/flake.nix' -c 'lua io.stdout:write(tostring(require("copilot.util").should_attach(vim.fn.bufnr("/etc/nixos/flake.nix"))), "\n")' -c 'qa!'` prints `true` (it prints `false` before the fix); the same command for a buffer under `~/notes` prints `false` both before and after.

### G3. Use the `cmd` keymap helper for `<cmd>...<cr>` mappings

**Where:** `nixvim-modules/base/basic.nix:50-57`, `nixvim-modules/heavy/misc.nix:7`, `nixvim-modules/heavy/misc.nix:11`, `nixvim-modules/base/lib.nix:10-13`
**Effort:** trivial -- **Risk:** none

**Problem:** `lib.nix:10-13` defines `cmd mode key excmd desc = keymap mode key "<cmd>${excmd}<cr>" desc`, a "keymap that runs an ex command, sparing callers the <cmd>...<cr> wrapping", and `filemgr.nix`, `fzf.nix` and `git.nix` use it. Three mappings still wrap by hand: `(keymap "n" "<c-j>" "<cmd>cnext<cr>" "next qf item")`, `(keymap "n" "<c-k>" "<cmd>cprev<cr>" "prev qf item")` and `(keymap "n" "<leader>u" "<cmd>packadd nvim.undotree | Undotree<cr>" "Undotree")`.

**Fix:**
- In `nixvim-modules/base/basic.nix:52-56`, use `inherit (config.lib) cmd;`, `(cmd "n" "<c-j>" "cnext" "next qf item")` and `(cmd "n" "<c-k>" "cprev" "prev qf item")`.
- In `nixvim-modules/heavy/misc.nix`, change line 7 to `inherit (config.lib) luaf keymap cmd;` and line 11 to `(cmd "n" "<leader>u" "packadd nvim.undotree | Undotree" "Undotree")`.

**Verify:** Checked in a scratch copy: the generated keymap tables are byte-identical for both variants. Before and after, `nix eval --raw .#packages.x86_64-linux.neovim.config.content` and `nix eval --raw .#packages.x86_64-linux.neovim-minimal.config.content` are byte-identical (`diff` the outputs).

### G4. nvim-surround: replace the three `no_*_mappings` globals with `nvim_surround_no_mappings`

**Where:** `nixvim-modules/base/editing.nix:27-31`
**Effort:** trivial -- **Risk:** none

**Problem:** `nvim_surround_no_normal_mappings`, `nvim_surround_no_insert_mappings` and `nvim_surround_no_visual_mappings` are all set to true. nvim-surround 4.0.5 has a single `g:nvim_surround_no_mappings` that "takes precedence over all other g:nvim_surround_no_*_mappings options" (`plugin/nvim-surround.lua:14-28`, `doc/nvim-surround.txt:326`): when it is set, the whole default block (insert, normal, visual) is skipped, and those are exactly the three groups disabled today. The Lua setup no longer reads mapping globals, and `editing.nix:45-55` already defines every wanted mapping explicitly.

**Fix:** In `nixvim-modules/base/editing.nix:27-31`, replace the `globals` block with `globals.nvim_surround_no_mappings = true;`.

**Verify:**
- `nix build .#checks.x86_64-linux.neovim-minimal`.
- `nix run .#neovim-minimal -- --headless -c 'lua for _, m in ipairs({{"n","ys"},{"n","s"},{"n","cs"},{"n","ds"},{"x","S"},{"x","gS"}}) do io.stdout:write(m[1], " ", m[2], " = ", vim.fn.maparg(m[2], m[1]), "\n") end' -c 'qa!'` prints the same before and after: `ys` and `x gS` empty, `s`, `cs`, `ds` and `x S` mapped to `<Plug>(nvim-surround-normal)`, `<Plug>(nvim-surround-change)`, `<Plug>(nvim-surround-delete)` and `<Plug>(nvim-surround-visual-line)`.

### G5. lib.nix: use `builtins.toJSON` instead of a `lib.generators.toJSON { }` binding

**Where:** `nixvim-modules/base/lib.nix:15`, `nixvim-modules/base/lib.nix:54`
**Effort:** trivial -- **Risk:** none

**Problem:** `toJSON = lib.generators.toJSON { };` is a roundabout `builtins.toJSON`: nixpkgs `lib/generators.nix:905` defines `toJSON = { }: lib.strings.toJSON`, which is `builtins.toJSON` (the two evaluate as equal). The binding has a single use, `value.text = toJSON v;` in the `snippets` file kind.

**Fix:** In `nixvim-modules/base/lib.nix`, delete line 15 (`toJSON = lib.generators.toJSON { };`) and the blank line after it, and change line 54 to `value.text = builtins.toJSON v;`. `lib` is still used elsewhere in the file.

**Verify:** Checked in a scratch copy: all `extraFiles` are byte-identical. Before and after, `nix eval --raw '.#packages.x86_64-linux.neovim.config.extraFiles."snippets/sh.json".text'` and the same for `"snippets/toml.json"` print the same JSON; `just lint` (deadnix) passes.

### G6. Use the `lua` helper instead of hand-written `__raw` attrs

**Where:** `nixvim-modules/heavy/fzf.nix:61`, `nixvim-modules/heavy/lang/rust.nix:16`, `nixvim-modules/base/lib.nix:3`
**Effort:** trivial -- **Risk:** none

**Problem:** Raw Lua otherwise always goes through `config.lib.lua` (`lib.nix:3`: `lua = action: { __raw = action; };`). These are the only two `__raw` uses in `nixvim-modules/`: `fzf.nix` already inherits `lua` but writes `fn.__raw = "require('fzf-lua').actions.file_sel_to_qf";`, and `rust.nix` writes `on_attach.__raw = ''...''`.

**Fix:**
- In `nixvim-modules/heavy/fzf.nix:61`, use `fn = lua "require('fzf-lua').actions.file_sel_to_qf";`. B16 edits the lines just above and can be done together.
- In `nixvim-modules/heavy/lang/rust.nix:16`, use `on_attach = config.lib.lua ''` with the same body (`config` is already a module argument). G7 edits the next two lines of the same string and can be done together.

**Verify:** Before and after, `nix eval --raw .#packages.x86_64-linux.neovim.config.content` is byte-identical (`diff` the outputs); if done together with G7 or B16, the diff contains only their changes.

### G7. rust `on_attach`: drop the unsupported `noremap` key and the unused `client` parameter

**Where:** `nixvim-modules/heavy/lang/rust.nix:17-18`
**Effort:** trivial -- **Risk:** none

**Problem:** The callback is `function(client, bufnr) local opts = { noremap = true, silent = true, buffer = bufnr }`. Neovim's `vim.keymap.set` documents "{noremap} is not supported; use {remap} instead" and forces `opts.noremap = true` when `remap` is nil (runtime `lua/vim/keymap.lua:6,74-76`), so the key has no effect. rustaceanvim calls `on_attach(client, bufnr)`, but `client` is never used in the body.

**Fix:** In `nixvim-modules/heavy/lang/rust.nix:17-18`, change to `function(_, bufnr)` and `local opts = { silent = true, buffer = bufnr }`. Can be done together with the G6 edit on line 16.

**Verify:**
- `nix build .#checks.x86_64-linux.neovim`; the `config.content` diff shows only these two lines of the rustaceanvim `on_attach`.
- In a Rust buffer with rust-analyzer attached, `:verbose xmap <c-space>` shows a buffer-local (`@`), non-remappable (`*`) mapping.

## H. Needs your decision

### H1. nix-cache-keygen: `chown builder` breaks it on non-builder hosts, it exits 1 when ~/.ssh exists, and it lives in Home Manager

**Where:** `home-modules/base/bin/default.nix:29-47`, `home-modules/base/bin/default.nix:52`, `nixos-modules/base/nix.nix:41`, `nixos-modules/base/nix.nix:86-90`, `nixos-modules/base/builder.nix:12`, `README.md:52`, `AGENTS.md:112-114`, `justfile:16`

**Context:**

- What the script does: if both `/etc/nix/cache.pem` and `/etc/nix/cache.pem.pub` are missing, it runs `sudo nix-store --generate-binary-cache-key "$(hostname)" ...`. Then it runs `sudo chown '${builder}:${builder}' '${private}' '${public}'` (with `builder = inputs.self.consts.builder.username`) and finally `[ ! -e "$HOME/.ssh" ] && yes "" | ssh-keygen -N ""`. It is installed through HM `home.packages`, but only `if osConfig != null`.
- Every host needs the key, which answers README.md:52 (`nix-cache-keygen # only if this machine is a builder XXX am I sure about this? seems like we need it regardless`). The base NixOS module sets `secret-key-files = "/etc/nix/cache.pem"` (nix.nix:41) and enables harmonia with `signKeyPaths = [ "/etc/nix/cache.pem" ]` (nix.nix:86-90) on every host. The `keys` output in outputs.nix reads every host's `keys/cache.pem.pub`, and hosts.nix adds those keys to the other hosts' `trusted-public-keys`.
- The chown breaks the script on 3 of 4 hosts. The `builder` account is created only under `lib.mkIf inputs.self.hosts.${...}.builder` (builder.nix:12), and only anuramat-bgm5 has `builder = true` in the registry. On f12, root and t480, `chown builder:builder` fails under writeShellApplication's errexit, so the script aborts before the ssh-keygen step.
- Nothing in the code needs `builder` to own the key. nix-daemon signs as root: a remote `nix-daemon --stdio` running as `builder` over ssh-ng forwards to the root daemon. Harmonia runs with `DynamicUser = true` and gets the key through `LoadCredential` (nixpkgs `nixos/modules/services/networking/harmonia.nix:152,160`). History: the original README step was `sudo chown nix-serve cache-priv-key.pem` (e60d38a7), which was for the old nix-serve cache server, and 17ad32a7 still had `sudo chown builder:builder "$private" "$public" # TODO hide somewhere in nix`. The reason for builder ownership is not recorded anywhere.
- Separate bug, to fix under every option: `[ ! -e "$HOME/.ssh" ] && yes "" | ssh-keygen -N ""` is the script's last command. When `~/.ssh` exists, which is the usual case, the test fails and the script exits 1 even though nothing went wrong. Replace it with `if [ ! -e "$HOME/.ssh" ]; then yes "" | ssh-keygen -N ""; fi`.
- Where the script lives: it works at the NixOS level but sits in HM. It reads `osConfig.nix.settings.secret-key-files`, hardcodes `public = "/etc/nix/cache.pem.pub"`, and is gated by `if osConfig != null`. The path `/etc/nix/cache.pem` is also hardcoded twice in nix.nix (lines 41 and 88), and justfile:16 (`nixos-pre`) hardcodes `/etc/nix/cache.pem.pub`.
- The `# TODO move and read public` at bin/default.nix:31 asks for the move, but "read public" is ambiguous. It could mean taking the public key path from config, or reading the key from the `keys` output.
- The script also mixes a system step (`sudo nix-store`, `chown`) with a per-user bootstrap step (`ssh-keygen` into `$HOME`), so moving it also means deciding where the ssh-keygen step goes.

**Options:** these are two independent choices, one about the chown and one about placement. Under all of them, also fix the trailing `&&` line as above and change README.md:52 to `nix-cache-keygen # every host: each signs its builds with /etc/nix/cache.pem and serves them via harmonia`.

- **(a)** Chown: drop it. Delete line 44, the `builder` binding and its `# its own group too, see nixos-modules/base/builder.nix` comment (lines 34-35), and the `inputs` arg, which is then unused. In AGENTS.md:112-114, remove `home-modules/base/bin/ (nix-cache-keygen)` from the consumers of `consts.builder`. -- The script then works on every host, and the key stays `root:root` as `nix-store` creates it. If anything outside the repo depends on `builder` owning the key on bgm5, it breaks; nothing in the repo does.
- **(b)** Chown: keep it only on builder hosts, gated on `inputs.self.hosts.${hostName}.builder`. -- Behaviour on bgm5 stays as it is. In HM this needs the hostname from `osConfig`; in a NixOS module the flag is available directly.
- **(c)** Placement: move the script into `nixos-modules/base/nix.nix`. Bind `cacheKey = "/etc/nix/cache.pem"` once and use it for `secret-key-files`, for `signKeyPaths`, and for the script's `private = cacheKey` / `public = "${cacheKey}.pub"`. Install it through `environment.systemPackages = [ (pkgs.writeShellApplication { name = "nix-cache-keygen"; ... }) ]`. Remove the block, the `osConfig` arg and the `if osConfig` from bin/default.nix. -- This resolves the TODO at line 31. You still need to decide whether the per-user ssh-keygen step stays in a system package or moves out, for example into the README bootstrap steps. Verify with `nix flake check`, and check that `nix eval .#nixosConfigurations.anuramat-bgm5.config.environment.systemPackages --apply 'map (p: p.name)'` contains nix-cache-keygen and that `secret-key-files` is unchanged.
- **(d)** Placement: keep it in HM, and only fix the chown and the exit status. -- This is the smaller diff, but the TODO stays open and the path stays hardcoded in three files.

**Recommendation:** for the chown, (a). Nothing in the repo reads the key as `builder`, and root ownership is exactly what nix-daemon and harmonia's `LoadCredential` need. To verify after a switch: a path built remotely from f12 still carries bgm5's signature (`nix path-info --sigs`), and `systemctl status harmonia` stays healthy. The evidence does not favour either placement option.

### H2. networkmanager-openconnect is installed as a system package but never registered as an NM plugin

**Where:** `nixos-modules/base/net.nix:52-54`, `nixos-modules/base/net.nix:21-23`, `nixos-modules/base/net.nix:25-39`

**Context:**

- `environment.systemPackages = with pkgs; [ networkmanager-openconnect ];` has no effect on NetworkManager. The NixOS networkmanager module creates `/etc/NetworkManager/VPN/<plugin>` and wires up dbus and tmpfiles only for packages listed in `networking.networkmanager.plugins` (nixpkgs `networkmanager.nix:131-139,566`). Upstream removed `enableDefaultPlugins` with the message "Configure the required plugins explicitly in `networking.networkmanager.plugins`".
- The evaluated `networking.networkmanager.plugins` is `[]`. On anuramat-bgm5, `/etc/NetworkManager/VPN` does not exist. The package's `.name` file (`networkManagerPlugin = "VPN/nm-openconnect-service.name"`) only ends up under `/run/current-system/sw/lib/NetworkManager/VPN`, which NM does not read.
- History: c08ff430 (2026-06-07 13:27, WIP) added the package. 45 minutes later, b20f5eb8 added the declarative `networking.openconnect.interfaces.uhd` (net.nix:25-39), which is the VPN in use now. The package looks like a leftover from an NM attempt that failed because of this bug.

**Options:**

- **(a)** Keep the NM route: delete net.nix:52-54 and set `networkmanager = { enable = true; plugins = [ pkgs.networkmanager-openconnect ]; };` at net.nix:21-23. -- openconnect VPNs can then be managed through nmcli or the GUI, on every host, because this is the base module. To verify: `nix eval --json .#nixosConfigurations.anuramat-f12.config.environment.etc --apply 'e: builtins.filter (n: builtins.match "NetworkManager/VPN.*" n != null) (builtins.attrNames e)'` lists the openconnect `.name` file, and after a rebuild `nmcli connection add type vpn vpn-type openconnect ...` is accepted.
- **(b)** Rely only on the systemd openconnect unit: delete net.nix:52-54 and change nothing else. -- Behaviour does not change, since the package does nothing today. NM still cannot manage openconnect VPNs.

### H3. podman: is `dns_enabled` on the default network still needed?

**Where:** `nixos-modules/local/containers.nix:8-10`

**Context:**

- The lines in question: `# > Required for containers under podman-compose to be able to talk to each other.`, `# TODO is this still needed?`, `defaultNetwork.settings.dns_enabled = true;`.
- With podman-compose 1.5.0 (the version here), a compose file with no `networks:` section, with a `default` network, or with exactly one network runs its services on a per-project `<project>_default` network. podman-compose creates that network with `podman network create`, and it gets DNS: podman-compose passes `--disable-dns` only for `x-podman.disable_dns`. Typical compose files therefore do not need this setting.
- The exception: a project that declares two or more networks, none of them named `default`, sets `default_net=None` (podman_compose.py:2339-2346, 1019-1027). Its services without `networks:` then run with `--network=bridge:alias=...`, which is the built-in `podman` network, and there this setting controls name resolution.
- The setting also covers plain rootful `podman run` without `--network`. Docker's default bridge has no DNS either.
- The NixOS module writes `/etc/containers/networks/podman.json` from this setting (podman/default.nix:249) and opens UDP 53 on the podman interface. Rootless podman does not read `/etc/containers/networks` at all.

**Options:**

- **(a)** Delete lines 8-10. This removes the quoted rationale comment and the TODO; the `podman` attrset keeps `enable` and `dockerCompat`. -- Containers on the rootful default `podman` network lose name resolution, which affects the multi-network compose case above and plain `podman run`, and UDP 53 closes on podman0. This is fine if you only use rootless podman or compose files that don't hit that case. To verify after a rebuild: run `podman-compose up -d` on a two-service project with no `networks:`, then check that `podman exec <svc1> getent hosts <svc2>` resolves and that `podman network inspect <project>_default` shows `dns_enabled: true`.
- **(b)** Keep the setting and replace the TODO with `# still needed for rootful podman-compose projects that declare several networks but no 'default' one (podman-compose then falls back to the 'podman' bridge)`. -- Behaviour does not change, and the comment records why the setting is there.

### H4. 64 lines of commented-out sway config in niri/default.nix

**Where:** `home-modules/heavy-linux/desktop/niri/default.nix:9-72`, `home-modules/heavy-linux/desktop/niri/default.nix:150-166`, `home-modules/heavy-linux/desktop/niri/zsa-tap.nix:2`

**Context:**

- Between the module args and the module body, lines 9-72 hold commented-out sway HM config: `# systemd = { xdgAutostart = true; variables = ...`, which includes `"DBUS_SESSION_BUS_ADDRESS" # for proton-bridge`, and `# wayland.windowManager.sway.config.input = { ... }`. Sway is no longer used.
- Already ported:
  - the keyboard repeat and layout settings and the touchpad settings, now in `programs.niri.settings.input` (lines 150-166);
  - the `grp:alt_space_toggle` layout switch, replaced by the `"Ctrl+Alt+Space".action.switch-layout` bind (keys.nix:152).
- Never ported, though niri can express them per device type:
  - `"*" = { accel_profile = "flat"; }` maps to niri `input.mouse.accel-profile = "flat"`;
  - the t480 TrackPoint settings `pointer_accel = "0.7"; accel_profile = "adaptive";` map to niri `input.trackpoint`. t480 is `deprecated = true` in the registry.
- Not expressible in niri: the per-device entries (the Razer entries are empty, plus ZSA `rotation_angle = "30"` and the t480 Synaptics `events = "disabled"`), because niri has no per-device input settings (zsa-tap.nix:2).
- So part of the block is reference material rather than purely outdated, and the rule against removing comments that are not outdated applies.

**Options:**

- **(a)** Port `input.mouse.accel-profile = "flat"`, and optionally `input.trackpoint` for t480, then delete lines 9-72. -- Mice get flat acceleration under niri (today they use niri's default). The commented-out block is removed.
- **(b)** Delete lines 9-72 without porting anything. -- The rendered niri config does not change. The flat-acceleration preference and the proton-bridge DBUS note are then only in git history. The commented-out block is removed.
- **(c)** Keep the block. -- No change.

To verify (a) or (b): `nix-instantiate --parse` succeeds; for (b), the rendered niri config is also unchanged.

### H5. Linux/Wayland-only shell helpers in the cross-platform base layer

**Where:** `home-modules/base/bash/bashrc.sh:7-12`, `home-modules/base/bash/bashrc.sh:14-21`, `home-modules/base/bash/bashrc.sh:23-27`, `home-modules/base/bash/bashrc.nix:9-16`, `home-modules/base/bash/bashrc.nix:42`, `home-modules/heavy-linux/packages.nix:8`, `home-modules/heavy-linux/packages.nix:37`, `home-modules/base/yazi.nix:98`, `nixvim-modules/heavy/custom.nix:11`

**Context:**

- The base bashrc.sh defines three helpers that need Linux-only tools:
  - `upload`: `curl -F "file=@$filename" https://0x0.st | tee >(wl-copy)`;
  - `take`: `echo "${paths[@]}" | wl-copy -n`;
  - `brexit`: `ddcutil setvcp 10 "$1" --display 1`.
- `ddcutil` and `wl-clipboard` are installed only in heavy-linux/packages.nix (lines 8 and 37), so the helpers are dead on darwin and on root. AGENTS.md says Linux-only additions belong in the `-linux` layers.
- The `orphans` package (bashrc.nix:10-16, installed at :42) relies on `ps -o unit` and `session-1.scope` (Linux/systemd). Its comment, `# either orphans or launched with \`swaymsg exec\``, refers to sway, which niri has replaced.
- Unlike `nai`, which must stay a function because it `cd`s, none of these four need shell state.
- The leak is wider than these helpers: base/yazi.nix:98 and nixvim heavy/custom.nix:11 also call `wl-copy`.
- Runtime impact is limited to dead functions on darwin and root, and evaluation is unaffected.
- heavy-linux has no `bin/` directory, so any move needs a new place to put these.
- One piece is straightforward whatever you choose: move `orphans` from base/bash/bashrc.nix to `home.packages` in home-modules/linux.nix, and reword its comment to `# processes reparented to PID 1 inside the tty login session (session-1.scope)`.

**Options for upload/take/brexit:**

- **(a)** Make them heavy-linux packages: `writeShellApplication`s with `runtimeInputs` (curl + wl-clipboard, coreutils + wl-clipboard, ddcutil), removed from bashrc.sh. -- They become binaries on PATH instead of interactive functions, with their dependencies pinned. To verify: the anuramat-darwin home config evaluates, `command -v upload take brexit orphans` resolves in a new shell on f12, and `just lint` passes.
- **(b)** Move them as functions into a bash snippet in heavy-linux, for example via `programs.bash.initExtra`. -- They keep their function semantics, but there is now a second bashrc fragment.
- **(c)** Leave them in base. -- No change; they stay dead on darwin and root.

None of these options covers the `wl-copy` calls in yazi.nix and nixvim custom.nix.

### H6. Sort the `# misc TODO categorize` packages

**Where:** `home-modules/heavy/lang/packages.nix:48-58`, `home-modules/heavy/lang/nix.nix:12`, `home-modules/heavy/jupyter.nix:8`

**Context:**

- `# misc TODO categorize` sits above rustlings, haskellPackages.hoogle, htmlq, jq, jsonschema, nixtract, pup, python3Packages.jupytext, yq-go and quicktype.
- The file's other groups are `# compilers`, `# linters`, `# formatters` and `# debuggers`.
- Possible homes in other files: heavy/lang/nix.nix has `nix-tree # dep tree`, and heavy/jupyter.nix installs `nbdime`.
- The installed package set is the same under every option, so this is purely a question of how to group them.

**Options:**

- **(a)** The audit's grouping: delete the TODO, then
  - move `nixtract` to heavy/lang/nix.nix next to `nix-tree`;
  - move `python3Packages.jupytext` to heavy/jupyter.nix next to `nbdime`;
  - put `haskellPackages.hoogle` under `# compilers` next to ghc/cabal-install/stack;
  - put the rest (htmlq, jq, jsonschema, pup, quicktype, yq-go) under `# data processing (json/yaml/html)`;
  - put `rustlings` under a new `# learning` group.

  -- hoogle is a documentation search engine, not a compiler, so `# compilers` is a loose fit.
- **(b)** Regroup within the file only, with no moves to other files: for example, a `# data processing` group plus whatever remains. -- Smaller diff.
- **(c)** Delete the TODO and leave the list as it is.

To verify any option: the sorted list of names in `home.packages` is the same before and after.

### H7. Move endpoints shared across layers (pastebin domain, uc3 cluster host) into consts

**Where:** `nixos-configurations/anuramat-root/web/pastebin.nix:5`, `nixvim-modules/heavy/custom.nix:10`, `nixos-modules/base/net.nix:37`, `home-modules/base/default.nix:67`, `outputs.nix:136`

**Context:**

- Each of these literals is written in both a NixOS module and an HM or nixvim module:
  - pastebin.nix:5 `domain = "bin.ctrl.sn";` and nixvim heavy/custom.nix:10 `url = "https://bin.ctrl.sn",`;
  - net.nix:37, where vpn-slice routes `bwunicluster.scc.kit.edu` through the uhd VPN, and base/default.nix:67 `HostName = "bwunicluster.scc.kit.edu";` for the `uc3` ssh host.
- consts already models this kind of cross-layer endpoint: `llama = { host; port; }` (outputs.nix:136) is consumed by bgm5/llama.nix and home-modules/base/hosts.nix.
- Adding these means designing part of the consts API:
  - names and shape (`pastebin` vs `web.pastebin.domain`, and `uc3.host` vs a `uc3` namespace that also holds `User = "hd_un330"` and the VPN ranges `129.206.0.0/16 147.142.0.0/16`);
  - whether these literals belong in consts at all.
- The gain is modest, and the change touches five files plus AGENTS.md.

**Options:**

- **(a)** Flat entries: add `pastebin = "bin.ctrl.sn";` and `uc3.host = "bwunicluster.scc.kit.edu";` to `consts`. Use them in:
  - pastebin.nix, as `domain = inputs.self.consts.pastebin;`. Its args are `_:` today, so it needs `inputs`.
  - custom.nix, as `url = "https://${inputs.self.consts.pastebin}"`. Nixvim modules already receive `inputs`.
  - the vpn-slice args in net.nix.
  - `HostName` in base/default.nix.

  Then add both to the consts list in AGENTS.md. -- To verify: `nix eval` of `services.wastebin.settings.WASTEBIN_BASE_URL` (root), of the HM `programs.ssh.settings.uc3.HostName`, and of the openconnect script all give the same values as before, and `nix flake check` passes, including the neovim checks.
- **(b)** Namespaced entries, for example `web.pastebin.domain` and a `uc3` attrset that also holds the user and the VPN ranges. -- More structure, and more churn.
- **(c)** Leave the literals where they are. -- No change; renaming either endpoint still means editing two places.

### H8. Duplicate home.packages entries: git/less/tmux and statix/deadnix (disputed)

**Where:** `home-modules/base/packages.nix:9`, `home-modules/base/packages.nix:11`, `home-modules/base/packages.nix:15`, `home-modules/heavy/lang/packages.nix:22`, `home-modules/heavy/lang/packages.nix:26`, `home-modules/heavy/editor.nix:23`, `home-modules/base/git/default.nix:28`, `home-modules/base/git/difft.nix:31`, `home-modules/base/misc.nix:31`

**Context:**

- The evaluated HM `home.packages` (f12 and bgm5) lists git, less, tmux, statix and deadnix twice each, and each pair has the same outPath (for example git-2.54.0, less-692, tmux-3.6a). buildEnv dedupes identical paths, so the profile is the same either way.
- git/less/tmux: base/packages.nix lists `git`, `less` and `tmux # just in case` under `# absolute minimum`. The same base layer also enables `programs.git` (git/default.nix:28), `programs.less` (git/difft.nix:31) and `programs.tmux` (misc.nix:31), and each of those adds its default package to `home.packages`. The duplicate `programs.less.enable` in bash/default.nix:124 is covered separately in B14.
- statix/deadnix: heavy/lang/packages.nix lists `deadnix # nix dead code` and `statix # nix` under `# linters`. Meanwhile heavy/editor.nix:23 adds `config.programs.nixvim.tools`, which evaluates to [hadolint, checkmake, statix, deadnix, biome, just, stylua, mbake, nixfmt, ruff, shfmt, typstyle, yamlfmt].
- For removal (one auditor, confirmed by one verifier): each package would be declared once, and the profile does not change. nixvim-modules/heavy/tools.nix says that this list exists to put these tools on PATH.
- For keeping (refuted by another verifier): the redundancy looks deliberate.
  - The base list is labelled `# absolute minimum`, and tmux carries `# just in case`. Keeping them there means the minimum does not depend on the `programs.*` toggles.
  - deadnix and statix are part of a curated `# linters` list. Removing them would make their presence on PATH depend on nvim-lint's nix linter config. The SLOP tools.nix extracts that config with a regex over nixvim module file paths (`.*/plugins/by-name/(conform-nvim|lint)(/.*)?`), so this is a hidden coupling.

**Options:**

- **(a)** Remove all five entries. -- Each package is declared once. git/less/tmux on PATH then depend on `programs.{git,less,tmux}.enable`, and statix/deadnix depend on nvim-lint's config via tools.nix. To verify: each of the five names still appears exactly once in `home.packages`, and the anuramat-darwin home config still evaluates.
- **(b)** Remove only git/less/tmux from base/packages.nix, and keep statix/deadnix in the curated linters list. -- This removes the duplicates whose source (`programs.*` in the same base layer) is easy to see, and avoids the coupling to the tools.nix regex.
- **(c)** Keep everything, and optionally add a comment saying the duplication is intentional. -- No change.

### Open TODO markers that need a decision or are nontrivial

None of these markers is fully covered by an H item above. The TODOs that H items resolve (bin/default.nix:31, containers.nix:9, lang/packages.nix:48, and the README.md:52 XXX) are not repeated here.

Needs a decision:

- `flake.nix:1` -- `# TODO use max-jobs to fetch caches` -- This marker sits in the wrong place: it came over from inputs.nix (24c7ce05), where it sat next to TODOs about input `follows` vs binary-cache hits that are now gone, and flake.nix only declares inputs. Nix 2.34 runs substitutions under `max-substitution-jobs` (16), separately from `max-jobs`, and `nix build --dry-run` already lists what will be fetched vs built. Either drop it, or move the intent to `nix.settings` in nixos-modules/base/nix.nix.
- `README.md:38` -- `todo:` (bootstrap checklist block: keys/tailscale/rekey, keygen script in the dev shell, unshallow the repo, gpg/pass init) -- This is a lowercase list, so the TODO grep misses it. It overlaps the README.md:32 bootstrap item and needs the same bootstrap design. Its "keygen script" line also relates to where nix-cache-keygen lives (H1).
- `nixos-modules/base/nix.nix:78` -- `# TODO speedFactor, maxJobs` -- In the evaluated f12 `buildMachines`, the entry for bgm5 has `maxJobs = 1`, `speedFactor = 1` and `supportedFeatures = []`. That means one remote job at a time, and `big-parallel`/`kvm` derivations are never offloaded. speedFactor does not matter with a single builder. Picking maxJobs and features, or adding them to the hosts registry, is a decision.
- `nixos-modules/local/default.nix:1` -- `# TODO tidy comments` -- Vague and a matter of taste (for example `"audio" # just in case (?)` and the verbose avahi/CUPS comments); there is nothing mechanical to do.
- `nixos-modules/local/default.nix:138` -- `# TODO move to local-minimal; the rest to local-heavy` -- No local-minimal or local-heavy NixOS layers exist (only base, local and laptop), and every local host imports all of `local`. Splitting it means adding a new layer, which is a design choice.
- `nixos-configurations/anuramat-bgm5/default.nix:96` -- `# TODO tmpfs` -- The target is unclear: `/tmp` via `boot.tmp.useTmpfs`, or an impermanent root. bgm5 is the build server, and a RAM-backed `/tmp` caps scratch space, so how far to take this is up to you.
- `home-modules/base/bash/default.nix:47` -- `# TODO just in case; verify/move` (above `LC_ALL = inputs.self.consts.user.locale;`) -- On NixOS, `LANG` already comes from `i18n.defaultLocale` (nixos-modules/base/default.nix:40) with no `LC_*` overrides, so this only matters for the standalone configs. Moving it to standalone.nix changes precedence: `home.language.base`/`LANG` there would no longer override every `LC_*` category the way `LC_ALL` does.
- `home-modules/base/bin/default.nix:49` -- `# TODO root ssh config from nix.nix?` -- This is in the wrong module: it refers to the buildMachines `BUG` comment in nixos-modules/base/nix.nix (sshUser/sshKey ignored, NixOS/nix#3423, manual `/root/.ssh/config`). Generating that config, for example via NixOS `programs.ssh.extraConfig`, first needs a re-check of whether the upstream bug still exists. At minimum, move the TODO next to that comment; this happens naturally if nix-cache-keygen moves to nix.nix (H1 option (c)).
- `home-modules/base/bash/git.sh:3` -- `# TODO reconsider stderr/stdout depending on usecases` -- An open-ended question about each function's I/O; it belongs to the planned rewrite (git.sh:5).
- `home-modules/heavy-linux/default.nix:25` -- `light = dark; # TODO find a light theme` -- Choosing a light icon theme to pair with Dracula is a matter of taste. Noctalia and stylix are dark-only anyway (`theme.mode = "dark"`).
- `home-modules/heavy-linux/desktop/portals.nix:40` -- `# TODO read and verify that all needs are covered with no overlap <https://wiki.archlinux.org/title/XDG_Desktop_Portal>` -- The overlap is real. The imported niri-flake HM module adds xdg-desktop-portal-gnome and `niri-portals.conf` (configPackages), and the user's `xdg.portal.config.common` (ScreenCast/Screenshot = wlr) overrides both. So xdp-gnome, which is the screencast path niri recommends, is installed but unused. Whether to use gnome or wlr for screencasting is a decision.
- `home-modules/heavy-linux/desktop/niri/keys.nix:8` -- `# TODO parameterize or smth` -- `bookdir = "${config.home.homeDirectory}/books"` is used only in this file. Where to define it is a choice: for example, add it to `customXdg` in home-modules/base/bash/default.nix:30 next to `XDG_PICTURES_DIR`, so the existing activation step creates it, or make it a sessionVariable like `TODO_FILE`.
- `home-modules/heavy-linux/desktop/niri/keys.nix:163` -- `# TODO markup screenshots` -- This needs a choice of tool and key. Both satty and swappy are installed (heavy-linux/packages.nix:18,21), and swappy is configured (heavy-linux/gui/default.nix:89). For example, a bind that spawns `sh -c 'wl-paste | swappy -f -'` after a screenshot would work.
- `home-modules/heavy-linux/gui/packages.nix:31` -- `# qtox # p2p IM XXX broken` -- qtox 1.18.3 evaluates in the pinned nixpkgs. Re-test it, then either re-enable it or delete the line.
- `home-modules/heavy-linux/gui/packages.nix:32` -- `# slack # XXX broken` -- `slack.meta.broken` is false in the pinned nixpkgs, so the breakage may only show at runtime. Re-test it, then either re-enable it or delete the line.
- `home-modules/heavy-linux/desktop/niri/autologin.nix:11` -- `# TODO create a new nix var with env vars that we put in the env` -- The variable list (`XDG_VTNR XDG_SESSION_TYPE XDG_SESSION_ID` for `dbus-update-activation-environment`) has a single consumer. A let-bound list only helps if something else shares it, for example niri-flake's environment or the broader `import-environment` commented out on line 10. Decide which variables are wanted first.
- `home-modules/heavy-linux/desktop/niri/autologin.nix:15` -- `# TODO these as a nix var as well` -- Same as line 11. The `unset-environment` list is copied verbatim from upstream niri-session, so a Nix variable adds lines without being reused anywhere.
- `home-modules/heavy/typst.nix:1` -- `# TODO try removing tmpdir` -- It is unclear what this means. Dropping `--tmpdir` from `mktemp` would put the PDF in the current directory, next to the `.typ` file, which changes behaviour. coreutils would still be needed for the GNU suffix template and `realpath`.
- `home-modules/heavy-linux/agents/frontends/claude.nix:33` -- `# TODO: curl -d 'test' ntfy.sh/topic-name` -- A remote push for the Notification hook needs a choice of service and topic. ntfy.sh topics are public to anyone who knows the name, so the topic would have to be a secret kept in agenix. It also overlaps with the existing `tgfy` Telegram notifier.
- `nixvim-modules/heavy/default.nix:61` -- `# TODO enable for typst?` -- This is possible: extend the filetype check in `onAttach` (currently `if vim.o.ft == "markdown"`) to typst, since typst raw blocks have treesitter injections. Whether you want otter LSP inside typst code blocks is a choice.
- `nixvim-modules/heavy/default.nix:74` -- `autoActivate = false; # TODO` -- A bare TODO, added in 35103220 with no context. `autoActivate = false` is required as long as the markdown-only `onAttach` stays, because nixvim's autoActivate runs `otter.activate()` on every LspAttach for all filetypes (plugins/by-name/otter/default.nix:103). The intent is unclear; one option is to replace the TODO with a comment explaining this.
- `nixvim-modules/heavy/lang/web.nix:10` -- `# TODO steal from ctrl.sn` -- The pinned `ctrlsn` input (flake.nix:41) has no formatter config (no treefmt, prettier or editorconfig), and its Makefile only runs the server and makes previews, so there is nothing to take. HTML is currently formatted only through the LSP fallback (superhtml, plus biome in JS projects). Pick an HTML formatter, or delete the TODO and the commented-out `formatters_by_ft.html` block.

Nontrivial:

- `README.md:32` -- `# TODO put these into the justfile, together with some other bootstrap stuff` -- `just nixos` already exports `pipe-operators` and could replace the nh/nixos-rebuild lines. But its `nixos-pre` dependency fails on a fresh machine: with no `~/.ssh/*.pub`, `xargs cp -ft keys_dir` runs `cp` with no operands. The bootstrap order (keygen, registry entry, rekey) needs to be designed first.
- `nixos-modules/base/net.nix:58` -- `# dnssec = "true"; # TODO breaks sometimes, try again with captive` -- This needs a runtime test on captive-portal networks. If you revisit it, note that the commented-out option has been renamed to `services.resolved.settings.Resolve.DNSSEC` (mkRenamedOptionModule in resolved.nix).
- `home-modules/base/bash/git.sh:4` -- `# TODO more local/readonly` -- Vague and applies to the whole file. The concrete leaking globals in `gcreate` are fixed in A3; the rest belongs to the rewrite.
- `home-modules/base/bash/git.sh:5` -- `# TODO total rehaul, then move` -- A large rewrite with no defined target. The concrete bugs are split out as A3, A4 and A5.
- `home-modules/heavy/packages.nix:3` -- `# TODO euporie (tui jupyter notebooks)` -- `pkgs.euporie` does not exist in the pinned nixpkgs, so it needs packaging, for example as a `buildPythonApplication` in overlays/default.nix like zotero-mcp.

## I. Considered and rejected

Recorded so they don't get re-proposed.

### I1. Rename `cmd` in the hostrun handler's `ask()`

**Where:** `home-modules/heavy-linux/agents/hostrun/handler.py:15`, `:28`, `:45`

**Proposal:** rename the function-local `cmd` in `ask()` to `argv`, since it shadows the module-level `cmd`.

**Why rejected:** it is a local in a 27-line function that never refers to the module-level command, so nothing can go wrong, and flake8 (which `writePython3Bin` runs) does not flag it. Readability-only churn.

### I2. Pass uc3-askpass to `uc3-master` via a shared `lib.uc3.askpassEnv`

**Where:** `home-modules/heavy-linux/agents/uc3/default.nix:76`, `home-modules/base/default.nix:9`, `:22`

**Proposal:** export `lib.uc3.askpassEnv` from the base layer and use it in the `uc3-master` unit and the `uc3` script, instead of reaching uc3-askpass through the profile path.

**Why rejected:** the dependency is not silent -- `home-modules/heavy-linux/agents/uc3/README.md` ("Host dependencies") documents it, and base is always imported with heavy-linux. The proposal adds coupling from a cross-platform base module to a heavy-linux service, and with a store path in `Environment`, any uc3-askpass rebuild would change the unit, so activation would restart the ssh master and spend a TOTP. The profile path avoids that.

