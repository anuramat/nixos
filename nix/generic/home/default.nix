{
  config,
  inputs,
  pkgs,
  ...
}:
let
  user = config.user.username;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {

    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${user} = {
      xdg.enable = true; # TODO what does this even do

      home.file = {
        ".exrc" = {
          source = ./exrc;
        };
      };

      programs = {

        home-manager.enable = true; # TODO same here

        gh = {
          enable = true;
          settings = {
            extensions = with pkgs; [
              gh-f
              gh-copilot
              # # wait until they appear
              # copilot-insights
              # token
            ];
            git_protocol = "ssh";
            prompt = true;
          };
        };

        bash = {
          enable = true;
          # TODO move everything around ffs
          bashrcExtra = ''
            source ${./xdg_shims.sh}
            [[ $- == *i* ]] || return
            for f in "${./bashrc.d}"/*; do source "$f"; done
            source ${./bashrc.sh}
          '';
        };

        git = {
          enable = true;
          difftastic = {
            enable = true;
            enableAsDifftool = true;
            display = "inline";
          };
          userEmail = config.user.email;
          userName = config.user.fullname;
          aliases = {
            st = "status";
            sh = "show --ext-diff";
            ch = "checkout";
            br = "branch";
            sw = "switch";
            cm = "commit";
            ps = "push";
            l = "log --ext-diff";
            lg = "log --ext-diff --oneline --graph --all --decorate";
            df = "diff";
            ds = "diff --staged";
          };
          ignores = [
            "*.db" # jupyter-lab, maybe etc
            ".DS_Store" # macOS
            ".cache/" # clangd, maybe etc
            ".devenv*"
            ".env"
            ".htpasswd"
            ".ipynb_checkpoints/"
            ".stack-work/" # haskell
            "__pycache__/"
            "node_modules/"
            "result" # nix
            "tags"
            "venv/"

            # pytorch lightning
            "*.ckpt"
            "lightning_logs"

            # go, maybe etc
            "cover.cov"
            "coverage.html"
            ".testCoverage.txt"

            # latex temp stuff
            "*.aux"
            "*.fdb_latexmk"
            "*.fls"
            "*.log"

            # direnv
            ".direnv/"
            ".envrc"
          ];
          attributes = [
            "*.ipynb diff=jupyternotebook merge=jupyternotebook"
          ];

          # TODO check jupyter notebook and nbdime later
          extraConfig = {
            pull.ff = "only";
            core.pager = "less -F";
            init.defaultBranch = "main";
            advice = {
              addEmptyPathspec = false;
              detachedHead = false;
            };
            push.autoSetupRemote = true;

            # WARN: XDGBDSV
            ghq.root = "~/.local/share/ghq";

            merge = {
              todo.driver = "todo merge %A %O %B";
              jupyternotebook = {
                driver = "git-nbmergedriver merge %O %A %B %L %P";
                name = "jupyter notebook merge driver";
              };
            };

            diff = {
              nodiff.command = "__nodiff() { echo skipping \"$1\"; }; __nodiff";
              jupyternotebook.command = "git-nbdiffdriver diff";
            };

            difftool = {
              prompt = false;
              nbdime.cmd = "git-nbdifftool diff \"$LOCAL\" \"$REMOTE\" \"$BASE\"";
            };
            pager.difftool = true;

            # I probably will never use this
            mergetool = {
              prompt = false;
              nbdime.cmd = "git-nbmergetool merge \"$BASE\" \"$LOCAL\" \"$REMOTE\" \"$MERGED\"";
            };

          };
        };

        readline = {
          enable = true;
          extraConfig = builtins.readFile ./inputrc;
        };

        librewolf = {
          enable = true;
          settings = {
            "browser.urlbar.suggest.history" = false;
            "widget.use-xdg-desktop-portal.file-picker" = 1;
            "identity.fxaccounts.enabled" = true;

            # since it breaks a lot of pages
            "privacy.resistFingerprinting" = false;

            "sidebar.verticalTabs" = true;
            # required by vertical tabs
            "sidebar.revamp" = true;

            # rejecting all; fallback -- do nothing
            "cookiebanners.service.mode" = 1;
            "cookiebanners.service.mode.privateBrowsing" = 1;
          };

        };

        neovim = {
          enable = true;
          package = pkgs.neovim;
          extraLuaPackages = ps: [
            # molten:
            ps.magick
          ];
          extraPackages = with pkgs; [
            # molten:
            imagemagick
            python3Packages.jupytext
            # mdmath.nvim
            librsvg
            # mcp
            github-mcp-server
            mcp-nixos
          ];
          extraPython3Packages =
            ps: with ps; [
              # molten {{{1
              # required:
              pynvim
              jupyter-client
              # images:
              cairosvg # to display svg with transparency
              pillow # open images with :MoltenImagePopup
              pnglatex # latex formulas
              # plotly figures:
              plotly
              kaleido
              # for remote molten:
              requests
              websocket-client
              # misc:
              pyperclip # clipboard support
              nbformat # jupyter import/export
              # }}}
            ];
        };
      };
    };
  };
}
