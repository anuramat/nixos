# TODO

Refactoring opportunities and straightforward TODOs, from an audit of the repo at commit 9d347469 (2026-10-09). Each item was reported by an auditor and then checked against the code by an independent verifier; line numbers refer to that commit, and some have shifted since, so apply fixes by content.

Items are numbered per section (A4, D12, ...). Sections A, D and F are confirmed and need no decision from you; section H collects everything that does; section I lists proposals that were rejected. Sections B (dead code), C (defaults and deprecated options), E (stale docs) and G (nixvim refactors) are done and were removed, as were the A, D and F items an agent could fully verify on its own; the ones left there need the user to check their effect (see Verifiability).

- A. Bugs and broken tooling
- D. TODOs that can be resolved now
- F. Refactors: flake, NixOS, Home Manager
- H. Needs your decision
- I. Considered and rejected
- Verifiability: what an agent can and cannot check for the remaining items

## A. Bugs and broken tooling

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

**Verify:** The three packages build (which runs shellcheck). Over ssh, `open-link https://example.com` opens the page in the niri session, and `echo hi | set-clipboard; get-clipboard` prints `hi`.

## D. TODOs that can be resolved now

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

## F. Refactors: flake, NixOS, Home Manager

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

## H. Needs your decision

### H1. nix-cache-keygen: `chown builder` breaks it on non-builder hosts, it exits 1 when ~/.ssh exists, and it lives in Home Manager

**Where:** `home-modules/base/bin/default.nix:29-47`, `home-modules/base/bin/default.nix:52`, `nixos-modules/base/nix.nix:41`, `nixos-modules/base/nix.nix:86-90`, `nixos-modules/base/builder.nix:12`, `AGENTS.md:112-114`, `justfile:16`

**Context:**

- What the script does: if both `/etc/nix/cache.pem` and `/etc/nix/cache.pem.pub` are missing, it runs `sudo nix-store --generate-binary-cache-key "$(hostname)" ...`. Then it runs `sudo chown '${builder}:${builder}' '${private}' '${public}'` (with `builder = inputs.self.consts.builder.username`) and finally `[ ! -e "$HOME/.ssh" ] && yes "" | ssh-keygen -N ""`. It is installed through HM `home.packages`, but only when `osConfig != null`.
- Every host needs the key (the README's bootstrap step now says so). The base NixOS module sets `secret-key-files = "/etc/nix/cache.pem"` (nix.nix:41) and enables harmonia with `signKeyPaths = [ config.nix.settings.secret-key-files ]` (nix.nix:86-90) on every host. The `keys` output in outputs.nix reads every host's `keys/cache.pem.pub`, and hosts.nix adds those keys to the other hosts' `trusted-public-keys`.
- The chown breaks the script on 3 of 4 hosts. The `builder` account is created only under `lib.mkIf inputs.self.hosts.${...}.builder` (builder.nix:12), and only anuramat-bgm5 has `builder = true` in the registry. On f12, root and t480, `chown builder:builder` fails under writeShellApplication's errexit, so the script aborts before the ssh-keygen step.
- Nothing in the code needs `builder` to own the key. nix-daemon signs as root: a remote `nix-daemon --stdio` running as `builder` over ssh-ng forwards to the root daemon. Harmonia runs with `DynamicUser = true` and gets the key through `LoadCredential` (nixpkgs `nixos/modules/services/networking/harmonia.nix:152,160`). History: the original README step was `sudo chown nix-serve cache-priv-key.pem` (e60d38a7), which was for the old nix-serve cache server, and 17ad32a7 still had `sudo chown builder:builder "$private" "$public" # TODO hide somewhere in nix`. The reason for builder ownership is not recorded anywhere.
- Separate bug, to fix under every option: `[ ! -e "$HOME/.ssh" ] && yes "" | ssh-keygen -N ""` is the script's last command. When `~/.ssh` exists, which is the usual case, the test fails and the script exits 1 even though nothing went wrong. Replace it with `if [ ! -e "$HOME/.ssh" ]; then yes "" | ssh-keygen -N ""; fi`.
- Where the script lives: it works at the NixOS level but sits in HM. It reads `osConfig.nix.settings.secret-key-files`, derives `public = "${private}.pub"` from it, and is gated on `osConfig != null`. The path `/etc/nix/cache.pem` is written once, in nix.nix's `secret-key-files`; justfile:16 (`nixos-pre`) hardcodes `/etc/nix/cache.pem.pub`, since it can't read Nix.
- The `# TODO move and read public` at bin/default.nix:31 asks for the move, but "read public" is ambiguous. It could mean taking the public key path from config, or reading the key from the `keys` output.
- The script also mixes a system step (`sudo nix-store`, `chown`) with a per-user bootstrap step (`ssh-keygen` into `$HOME`), so moving it also means deciding where the ssh-keygen step goes.

**Options:** these are two independent choices, one about the chown and one about placement. Under all of them, also fix the trailing `&&` line as above.

- **(a)** Chown: drop it. Delete line 44, the `builder` binding and its `# its own group too, see nixos-modules/base/builder.nix` comment (lines 34-35), and the `inputs` arg, which is then unused. In AGENTS.md:112-114, remove `home-modules/base/bin/ (nix-cache-keygen)` from the consumers of `consts.builder`. -- The script then works on every host, and the key stays `root:root` as `nix-store` creates it. If anything outside the repo depends on `builder` owning the key on bgm5, it breaks; nothing in the repo does.
- **(b)** Chown: keep it only on builder hosts, gated on `inputs.self.hosts.${hostName}.builder`. -- Behaviour on bgm5 stays as it is. In HM this needs the hostname from `osConfig`; in a NixOS module the flag is available directly.
- **(c)** Placement: move the script into `nixos-modules/base/nix.nix`, with `private = config.nix.settings.secret-key-files` and `public = "${private}.pub"`. Install it through `environment.systemPackages = [ (pkgs.writeShellApplication { name = "nix-cache-keygen"; ... }) ]`. Remove the block, the `osConfig` arg and the `lib.optional (osConfig != null) nix-cache-keygen` from bin/default.nix. -- This resolves the TODO at line 31. You still need to decide whether the per-user ssh-keygen step stays in a system package or moves out, for example into the README bootstrap steps. Verify with `nix flake check`, and check that `nix eval .#nixosConfigurations.anuramat-bgm5.config.environment.systemPackages --apply 'map (p: p.name)'` contains nix-cache-keygen and that `secret-key-files` is unchanged.
- **(d)** Placement: keep it in HM, and only fix the chown and the exit status. -- This is the smaller diff, but the TODO stays open.

**Recommendation:** for the chown, (a). Nothing in the repo reads the key as `builder`, and root ownership is exactly what nix-daemon and harmonia's `LoadCredential` need. To verify after a switch: a path built remotely from f12 still carries bgm5's signature (`nix path-info --sigs`), and `systemctl status harmonia` stays healthy. The evidence does not favour either placement option.

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
- consts already models this kind of endpoint: `llama = { host; port; decisionPort; }` (outputs.nix:136), consumed by bgm5/llama.nix.
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
- git/less/tmux: base/packages.nix lists `git`, `less` and `tmux # just in case` under `# absolute minimum`. The same base layer also enables `programs.git` (git/default.nix:28), `programs.less` (git/difft.nix:31) and `programs.tmux` (misc.nix:31), and each of those adds its default package to `home.packages`. The duplicate `programs.less.enable` in bash/default.nix was already removed (B14, done).
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

None of these markers is fully covered by an H item above. The TODOs that H items resolve (bin/default.nix:31, containers.nix:9, lang/packages.nix:48) are not repeated here.

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
- `home-modules/base/bash/git.sh:4` -- `# TODO more local/readonly` -- Vague and applies to the whole file. The concrete leaking globals in `gcreate` are fixed; the rest belongs to the rewrite.
- `home-modules/base/bash/git.sh:5` -- `# TODO total rehaul, then move` -- A large rewrite with no defined target. The concrete bugs are split out as A4 and A5 (the `gcreate` one is fixed).
- `home-modules/heavy/packages.nix:3` -- `# TODO euporie (tui jupyter notebooks)` -- `pkgs.euporie` does not exist in the pinned nixpkgs, so it needs packaging, for example as a `buildPythonApplication` in its own overlay under overlays/.

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


## Verifiability

What an agent can check on its own for the remaining items, using an eval, a build or a headless run, without a switch, a GUI or interactive use. The A, D, F and G items it could fully verify are done and were removed.

### Only partly verifiable

The build or eval side can be checked, but the real effect needs the user.

- A4 (`gwt`), A5 (`gclone`): testable only with fzf, gum and gh stubbed; real picker use is not.
- A13 (niri shortcuts): the scripts build and open-link's PATH has coreutils; opening a link in the niri session is not testable.
- D12 (hotdoc): it builds, and a stubbed zathura gets killed on SIGINT; the real zathura window is not testable.
- D13 (Firefox engines): eval shows the engines hidden; whether Firefox hides them shows only after a restart.
- F13 (autologin profile): eval shows the new block; niri starting on tty1 needs a login.

### Unambiguous parts of H

Two pieces of H items have one fix whatever is decided for the rest:

- H1: the trailing `[ ! -e "$HOME/.ssh" ] && ... ssh-keygen` makes nix-cache-keygen exit 1 whenever `~/.ssh` exists. Testable only with `sudo` stubbed.
- H5: moving `orphans` to `home-modules/linux.nix`, checkable by eval.

The rest of H and the open TODO markers need a decision or runtime testing.
