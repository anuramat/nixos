# the fleet monitor: a fleet-poll-NAME user service per section keeps
# $XDG_STATE_HOME/fleet/NAME.json up to date, except for the current host's,
# which is cheap enough to probe on demand; `fleet --json` gathers them, and
# both the noctalia widget and `fleet` itself render that, laid out by
# layout.luau; a section is a node
# with `name`, `at` (seconds since the epoch of the last successful fetch),
# `err` (the last fetch's error) and `offline` (the host was unreachable on the
# last fetch, which greys out the section):
#   NODE = { cells: [CELL], children: [NODE] }
#   CELL = { text, style?, width? } | { since } | { until }
# a section's cells go to its header, after its name, and each child is a row,
# followed by its own children, indented; `style` is a noctalia color role
# (default on_surface), `width` the length in characters that `text` is
# wrapped at, unless it's the row's last cell, which is wrapped at the end of
# the row; `since` and `until` are seconds since the epoch, rendered relative
# to now
# the color roles, by their meaning in the monitor:
#   primary             title: section names
#   outline             muted: metadata (times, battery, groups) and inactive
#                       states (offline hosts' sections, quiet profile)
#   on_surface_variant  secondary: descriptions and side details
#   on_surface          body: plain cells
#   error               alert: errors, overdue ETAs, an awake dGPU
{
  lib,
  config,
  osConfig ? null,
  pkgs,
  inputs,
  ...
}:
let
  inherit (config.lib.shellcheck) excludeShellChecks;
  probe = pkgs.callPackage ./probe.nix { inherit inputs; };
  # unknown on standalone Home Manager, where every host is polled as a remote one
  localHost = if osConfig == null then "" else osConfig.networking.hostName;
  dir = "${config.xdg.stateHome}/fleet";
  script =
    name: runtimeInputs: text:
    pkgs.writeShellApplication {
      inherit
        name
        runtimeInputs
        text
        excludeShellChecks
        ;
    };

  # name -> poll interval in seconds (null: probed by `fleet` itself) and the
  # command printing the section
  hosts =
    probe.hosts
    |> lib.partition (h: h == localHost)
    |> ({ right, wrong }: right ++ wrong)
    |> map (h: {
      name = h;
      interval = if h == localHost then null else 30;
      # ssh exits with 255 when it can't reach the host
      cmd = script "fleet-${h}" [ pkgs.jq ] ''
        if out=$(${lib.getExe probe} ${h}); then
          jq -nR -L ${./.} -f ${./host.jq} <<<"$out"
        elif [ $? = 255 ]; then
          echo '{"offline": true}'
        else
          exit 1
        fi
      '';
    });
  sections = hosts ++ [
    {
      # uc3 is fetched hourly by uc3-status.service (see agents/uc3), which a
      # refresh starts early; a failed fetch keeps the snapshot and leaves its
      # error in status.err
      name = "uc3";
      interval = 10;
      cmd =
        script "fleet-uc3"
          [
            pkgs.coreutils
            pkgs.jq
            pkgs.systemd
          ]
          ''
            d=${config.lib.uc3.stateDir}
            [ -z "''${REFRESH-}" ] || systemctl --user start uc3-status.service || :
            # nothing to show before the first successful fetch
            [ -e "$d/status" ] || { echo '{}' && exit; }
            jq -Rs -L ${./.} -f ${./uc3.jq} --argjson at "$(stat -c %Y "$d/status")" \
              --arg err "$(tail -n 1 "$d/status.err")" "$d/status"
          '';
    }
    {
      # the CLIs' own access tokens are used: Claude's is refreshed by starting
      # the CLI, whose refresh is safe to race with running sessions; an expired
      # Codex one fails its provider until the CLI's next run refreshes it
      name = "tokens";
      interval = 300;
      cmd =
        script "fleet-tokens"
          [
            pkgs.claude-code
            pkgs.coreutils
            pkgs.curl
            pkgs.jq
            pkgs.util-linux
          ]
          ''
            # the credentials are located by the session variables, which user services don't get
            set +u
            # shellcheck source=/dev/null
            . ${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh
            set -u
            # usage URL ARGS...: GETs URL with the headers on stdin (keeping the
            # tokens off the command line), or prints {error}
            usage() {
              local out
              if out=$(curl -fsS --max-time 20 -H @- "$@" 2>&1); then echo "$out"; else jq -n --arg e "$out" '{error: $e}'; fi
            }
            creds=$CLAUDE_CONFIG_DIR/.credentials.json
            # claude blanks the tokens when the server rejects the refresh token
            if jq -e '.claudeAiOauth.refreshToken == ""' "$creds" >/dev/null; then
              claude='{"error": "not logged in"}'
            else
              # only the TUI refreshes the token (`claude auth status` doesn't), and it needs a pty
              if jq -e '.claudeAiOauth.expiresAt < now * 1000' "$creds" >/dev/null; then
                timeout 5 script -qec claude /dev/null </dev/null >/dev/null 2>&1 || :
              fi
              claude=$(jq -r '"Authorization: Bearer \(.claudeAiOauth.accessToken)"' "$creds" |
                usage https://api.anthropic.com/api/oauth/usage -H 'anthropic-beta: oauth-2025-04-20')
            fi
            codex=$(jq -r '.tokens | "Authorization: Bearer \(.access_token)\nChatGPT-Account-Id: \(.account_id)"' "$CODEX_HOME/auth.json" |
              usage https://chatgpt.com/backend-api/wham/usage)
            jq -n --argjson claude "$claude" --argjson codex "$codex" -f ${./tokens.jq}
          '';
    }
  ];
  poll = script "fleet-poll" (with pkgs; [
    coreutils
    jq
  ]) (builtins.readFile ./poll.sh);
  # usage: fleet [--json | refresh SECTION]
  # prints the sections, laid out like the widget does, in the terminal's
  # width (`COLUMNS=N fleet` for another one); `refresh` makes one fetch its
  # section right away, and waits for it
  fleet =
    script "fleet"
      (with pkgs; [
        coreutils
        jq
        lune
        ncurses
        systemd
      ])
      ''
        if [ "''${1-}" = refresh ]; then
          f=${dir}/$2.json
          old=$(stat -c %.9Y "$f")
          systemctl --user kill -s USR1 "fleet-poll-$2.service"
          while [ "$(stat -c %.9Y "$f")" = "$old" ]; do sleep 0.2; done
          exit
        fi
        json=$(
          {
            ${
              sections
              |> map (
                s:
                if s.interval == null then
                  "${lib.getExe s.cmd} || echo '{\"err\": \"failed\"}'"
                else
                  "cat ${dir}/${s.name}.json 2>/dev/null || echo '{}'"
              )
              |> lib.concatLines
            }
          } | jq -cs --argjson names ${
            sections
            |> map (s: s.name)
            |> builtins.toJSON
            |> lib.escapeShellArg
          } '[$names, .] | transpose | map({name: .[0]} + .[1])'
        )
        if [ "''${1-}" = --json ]; then
          echo "$json"
          exit
        fi
        color=
        [ ! -t 1 ] || color=color
        # cli.luau requires layout.luau next to it
        lune run ${./.}/cli.luau "$(tput cols)" $color <<<"$json"
      '';

  # centered; cx and cy are fractions of the output's logical size
  widget = {
    type = "anuramat/fleet-monitor:jobs";
    cx = 0.5;
    cy = 0.5;
    settings.font_size = 20;
  };
in
{
  home.packages = [ fleet ];

  systemd.user.services =
    sections
    |> lib.filter (s: s.interval != null)
    |> map (s: {
      name = "fleet-poll-${s.name}";
      value = {
        Unit.Description = "fleet monitor's ${s.name} section";
        Service = {
          ExecStart = "${lib.getExe poll} ${s.name} ${toString s.interval} ${lib.getExe s.cmd}";
          StateDirectory = "fleet";
          Restart = "always";
          RestartSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };
    })
    |> lib.listToAttrs;

  # local plugins are scanned from here and activated by `plugins.enabled`
  xdg.dataFile = {
    "noctalia/plugins/fleet-monitor/plugin.toml".source =
      (pkgs.formats.toml { }).generate "plugin.toml"
        {
          id = "anuramat/fleet-monitor";
          name = "Fleet monitor";
          plugin_api = 23;
          desktop_widget = [
            {
              id = "jobs";
              entry = "widget.luau";
              # card size as fractions of the output's logical size, and the
              # font size, which the rest of the layout scales with (14 is
              # noctalia's default); unlike the widget box (`box_width`,
              # `box_height`), which scales the content to fit it, these keep
              # the font size fixed, and the content scrolls when it doesn't fit
              setting =
                lib.mapAttrsToList
                  (key: default: {
                    inherit key default;
                    type = if builtins.isFloat default then "float" else "int";
                    label_key = key;
                  })
                  {
                    width = 0.95;
                    height = 0.89;
                    font_size = 14;
                  };
            }
          ];
        };
    "noctalia/plugins/fleet-monitor/widget.luau".source = pkgs.replaceVars ./widget.luau {
      inherit localHost;
      fleet = lib.getExe fleet;
    };
    "noctalia/plugins/fleet-monitor/layout.luau".source = ./layout.luau;
  };

  programs.noctalia.settings = {
    plugins.enabled = [ "anuramat/fleet-monitor" ];
    # without `output`, noctalia uses the first output instead of a
    # host-specific connector
    desktop_widgets.widget.fleet = widget;
    lockscreen_widgets.widget.fleet = widget;
  };
}
