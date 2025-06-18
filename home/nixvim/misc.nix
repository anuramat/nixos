{
  lib,
  inputs,
  pkgs,
  ...
}:
let
  sub = rev: builtins.substring 0 7 rev;
  _mkMap =
    key: action: desc:
    {
      mode = "n";
      inherit key action;
    }
    // (
      if builtins.typeOf action == "string" then
        {
          action = "<cmd>${action}<cr>";
          desc = action;
        }
      else
        { }
    );
  mkMap =
    k: a: d:
    _mkMap ("<leader>hk") a d;
in
{
  keymaps = [
    {
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<cr>";
      options.desc = "Undotree";
    }
  ];

  plugins = {
    web-devicons.enable = true;

    sniprun.enable = true;

    nvim-lightbulb.enable = true;

    grug-far.enable = true;

    dressing.enable = true;

    # namu = {
    #   keys = [
    #     [
    #       "<leader>s"
    #       "<cmd>Namu symbols<cr>"
    #       {
    #         desc = "Jump to LSP symbol";
    #         silent = true;
    #       }
    #     ]
    #   ];
    #   opts = {
    #     colorscheme = {
    #       enable = true;
    #     };
    #     namu_symbols = {
    #       enable = true;
    #       options = [ ];
    #     };
    #     ui_select = {
    #       enable = true;
    #     };
    #   };
    # };

    undotree.enable = true;

    schemastore.enable = true;

    flash = {
      enable = true;
      settings = {
        label = {
          after = false;
          before = true;
        };
        modes = {
          char = {
            enabled = false;
          };
          treesitter = {
            grammars = [ pkgs.vimPlugins.nvim-treesitter-parsers.todotxt ];
            label = {
              rainbow = {
                enabled = true;
              };
            };
          };
        };
      };
      lazyLoad = {
        settings = {
          keys = [
            {
              __unkeyed_1 = "<leader>r";
              __unkeyed_2 = "function() require('flash').jump() end";
              desc = "Jump";
              mode = "n";
            }
            {
              __unkeyed_1 = "r";
              __unkeyed_2 = "function() require('flash').treesitter() end";
              desc = "TS node";
              mode = "o";
            }
          ];
        };
      };
    };

    todo-comments = {
      enable = true;
      settings = {
        signs = false;
        highlight = {
          keyword = "bg"; # only highlight the KEYWORD
          pattern = ''<(KEYWORDS)>'';
          multiline = false;
        };
        search = {
          pattern = ''\b(KEYWORDS)\b'';
        };
      };
    };
  };

  extraPlugins = [
    (
      let
        rev = "7a70a7e5efc2af5025134c395bd27e3ada9b8629";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "wastebin.nvim";
        version = "7a70a7e";
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "matze";
          repo = "wastebin.nvim";
          sha256 = "0r5vhmd30zjnfld9xvcpyjfdai1bqsbw9w6y51d36x3nsxhjbm2y";
        };
      }
    )
    (
      let
        rev = "062fd90490ddd9c2c5b749522b0906d4a2d74f72";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "figtree.nvim";
        version = sub rev;
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "anuramat";
          repo = "figtree.nvim";
          sha256 = "08xzv1h3v3xkyx4v0l068i65qvly9mxjnpswd33gb5al1mfqdmbg";
        };
      }
    )

    (
      let
        rev = "a3a3d81d12b61a38f131253bcd3ce5e2c6599850";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "namu.nvim";
        version = sub rev;
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "bassamsdata";
          repo = "namu.nvim";
          sha256 = "04s6gh0ryhc6b487szqj3pkgynnx0xfr0b1q4c7kynf62bb4h4xa";
        };
      }
    )
    (
      let
        rev = "6bc34b0dcf9e12066c15cc29c4b33a8066e4dc37";

        # Pre-build the Node.js dependencies
        nodeDeps = pkgs.buildNpmPackage {
          pname = "mdmath-js-deps";
          version = "1.0.0";
          src =
            pkgs.fetchFromGitHub {
              inherit rev;
              owner = "anuramat";
              repo = "mdmath.nvim";
              sha256 = "sha256-HesDrwB0u2fKvdJzTuZqBi1MBVVBFWBi4ysnJ84PiWQ=";
            }
            + "/mdmath-js";
          npmDepsHash = "sha256-yUyLKZQGIibS/9nHWnh0yvtZqza3qEpN9UNqRaNK53Y=";
          dontNpmBuild = true;
          installPhase = ''
            mkdir -p $out
            cp -r . $out/
            chmod +x $out/src/processor.js
          '';
        };
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "mdmath.nvim";
        version = sub rev;
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "anuramat";
          repo = "mdmath.nvim";
          sha256 = "sha256-HesDrwB0u2fKvdJzTuZqBi1MBVVBFWBi4ysnJ84PiWQ=";
        };
        doCheck = false;
        postPatch = ''
                    # Replace mdmath-js with pre-built version
                    rm -rf mdmath-js
                    cp -r ${nodeDeps} mdmath-js
                    chmod -R u+w mdmath-js
                    
                    # Create a wrapper for processor.js with proper PATH
                    mv mdmath-js/src/processor.js mdmath-js/src/processor-unwrapped.js
                    cat > mdmath-js/src/processor.js << 'EOF'
          #!/usr/bin/env node
          process.env.PATH = "${
            pkgs.lib.makeBinPath [
              pkgs.librsvg
              pkgs.imagemagick
              pkgs.nodejs
            ]
          }" + ":" + (process.env.PATH || "");
          import('./processor-unwrapped.js');
          EOF
                    chmod +x mdmath-js/src/processor.js
        '';
        propagatedBuildInputs = with pkgs; [
          nodejs
          imagemagick
          librsvg
        ];
      }
    )
  ];
  extraConfigLua = ''
    require('wastebin').setup({
      url = 'https://bin.ctrl.sn',
      open_cmd = '__wastebin() { wl-copy "$1" && xdg-open "$1"; }; __wastebin',
      ask = false,
    })
  '';
}
