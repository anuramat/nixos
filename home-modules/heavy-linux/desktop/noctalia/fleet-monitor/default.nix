# the fleet monitor: a fleet-poll-NAME user service per section keeps
# $XDG_STATE_HOME/fleet/NAME.json up to date, except for the current host's,
# which is cheap enough to probe on demand; `fleet --json` gathers them, and
# both the noctalia widget and `fleet` itself render that, laid out by
# layout.luau; a section is a node
# with `name`, `at` (seconds since the epoch of the last successful fetch) and
# `err` (the last fetch's error):
#   NODE = { cells: [CELL], children: [NODE] }
#   CELL = { text, style?, width? } | { since } | { until }
# a section's cells go to its header, after its name, and each child is a row,
# followed by its own children, indented; `style` is a noctalia color role
# (default on_surface), `width` the length in characters that `text` is
# wrapped at, unless it's the row's last cell, which is wrapped at the end of
# the row; `since` and `until` are seconds since the epoch, rendered relative
# to now
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
      cmd = script "fleet-${h}" [ pkgs.jq ] "${lib.getExe probe} ${h} | jq -nR -L ${./.} -f ${./host.jq}";
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
      # `caut usage` reads no cache: every run queries the providers' APIs, so
      # it is polled no more often than caut's own freshness threshold; when
      # only some providers fail, it exits non-zero, but prints the rest along
      # with the errors
      name = "tokens";
      interval = 300;
      cmd = script "fleet-tokens" [ pkgs.jq ] ''
        # the credentials are located by the session variables, which user services don't get
        set +u
        # shellcheck source=/dev/null
        . ${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh
        set -u
        { ${lib.getExe' pkgs.caut "caut"} usage --json || :; } | jq -f ${./tokens.jq}
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
