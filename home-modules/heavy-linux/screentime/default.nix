# SLOP
# AI-based screen time tracking. The zellij tracker logs a class timeline for
# every focused pane of this host's zellij sessions; the screen tracker
# (`screentime.screen`) follows niri focus and logs classes, or the zellij
# pane on screen, which `screentime report` replaces with the pane's classes
# from the host that runs the session. Classes come from bgm5's decision
# model, or from the dir and app maps below.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (inputs.self.consts.llama) host decisionPort;
  home = config.home.homeDirectory;
  settings = {
    url = "http://${host}:${toString decisionPort}/v1/systemone";
    instructions = lib.concatStringsSep " " [
      "Which class does what the user is doing belong to?"
      "Pick the most specific class that fits: the project classes (nixos, thesis, vicode) first,"
      "then coding, photography and chat, then tech, then web, and misc last."
    ];
    # the criteria are the only definition of a class
    # the criteria are the only definition of a class; the order is the report's
    classes = [
      {
        name = "nixos";
        criteria = "NixOS and nix: the NixOS configuration, nix code, NixOS wiki and docs, nix forums";
      }
      {
        name = "thesis";
        criteria = "research related to diffusion models: papers, notes, experiments";
      }
      {
        name = "vicode";
        criteria = "stuff relevant to writing a coding agent in Rust";
      }
      {
        name = "coding";
        criteria = "programming, debugging or terminal work not covered by a project class";
      }
      {
        name = "photography";
        criteria = "editing in darktable, photography books, videos, articles";
      }
      {
        name = "chat";
        criteria = "Telegram, Discord";
      }
      {
        name = "tech";
        criteria = "reading on science, tech or software, e.g. in the web browser";
      }
      {
        name = "web";
        criteria = "web browsing not covered by the classes above";
      }
      {
        name = "misc";
        criteria = "everything else";
      }
    ];
    # pane cwd -> class, by the longest prefix, without the model
    dirs = {
      "/etc/nixos" = "nixos";
      "${home}/.local/share/ghq/github.com/anuramat/diffusion" = "thesis";
      "${home}/.local/share/ghq/github.com/anuramat/vicode" = "vicode";
    };
    # niri app_id -> class, without the model
    apps = {
      "org.telegram.desktop" = "chat";
      discord = "chat";
      "org.darktable.darktable" = "photography";
    };
    # a title-only answer at least this confident skips the screenshot
    threshold = 0.7;
    # a target's first classification gets both answers, and the
    # classification log keeps the targets in plain text instead of hashes
    calibration = true;
  };

  screentime = pkgs.python3Packages.buildPythonApplication {
    pname = "screentime";
    version = "0.1.0";
    pyproject = true;
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./pyproject.toml
        ./screentime
        ./tests
      ];
    };
    build-system = [ pkgs.python3Packages.setuptools ];
    nativeCheckInputs = [ pkgs.python3Packages.pytestCheckHook ];
    makeWrapperArgs = [
      "--prefix PATH : ${
        lib.makeBinPath [
          config.programs.niri.package
          config.programs.zellij.package
          pkgs.coreutils
          pkgs.grim
          pkgs.openssh
        ]
      }"
    ];
  };
  configFile = pkgs.writeText "screentime.json" (builtins.toJSON settings);
  service = Unit: cmd: {
    inherit Unit;
    Service = {
      ExecStart = "${lib.getExe' screentime "screentime"} ${cmd}";
      Restart = "always";
      RestartSec = 10;
    };
  };
  # only the main process: the niri event stream would die of the signal
  signal = sig: "systemctl --user kill --kill-whom=main -s ${sig} screentime.service";
in
{
  options.screentime.screen = lib.mkEnableOption "the screen tracker and the report";

  config = lib.mkMerge [
    {
      home.packages = [ screentime ];
      xdg.configFile."screentime/config.json".source = configFile;
      systemd.user.services.screentime-zellij =
        service {
          Description = "screen time tracker for zellij panes";
          X-Restart-Triggers = [ "${configFile}" ];
        } "zellij"
        // {
          Install.WantedBy = [ "default.target" ];
        };
    }
    (lib.mkIf config.screentime.screen {
      systemd.user.services.screentime =
        service {
          Description = "screen time tracker";
          After = [ config.wayland.systemd.target ];
          PartOf = [ config.wayland.systemd.target ];
          X-Restart-Triggers = [ "${configFile}" ];
        } "screen"
        // {
          Install.WantedBy = [ config.wayland.systemd.target ];
        };
      # the lock counts as idle
      programs.noctalia.settings.hooks = {
        session_locked = [ (signal "SIGUSR1") ];
        session_unlocked = [ (signal "SIGUSR2") ];
      };
    })
  ];
}
