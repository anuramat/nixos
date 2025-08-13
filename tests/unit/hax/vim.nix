{ pkgs, lib }:
let
  hax = import ../../../hax/vim.nix { inherit lib; };
in
{
  luaHelpers = {
    basic = {
      expr = hax.lua ''vim.cmd("echo")'';
      expected = {
        __raw = ''vim.cmd("echo")'';
      };
    };

    wrapped = {
      expr = hax.luaf "return 42";
      expected = {
        __raw = "function() return 42 end";
      };
    };
  };

  keymapFunctions = {
    stringAction = {
      expr = hax.set "gd" "Telescope lsp_definitions" "Go to definition";
      expected = {
        mode = "n";
        key = "gd";
        action = "<cmd>Telescope lsp_definitions<cr>";
        options = {
          desc = "Go to definition";
        };
      };
    };

    stringActionNoDesc = {
      expr = hax.set "gr" "Telescope lsp_references" "";
      expected = {
        mode = "n";
        key = "gr";
        action = "<cmd>Telescope lsp_references<cr>";
        options = {
          desc = "Telescope lsp_references";
        };
      };
    };

    luaAction = {
      expr =
        hax.set "<leader>p" (hax.lua ''require("telescope").extensions.projects.projects()'')
          "Projects";
      expected = {
        mode = "n";
        key = "<leader>p";
        action = {
          __raw = ''require("telescope").extensions.projects.projects()'';
        };
        options = {
          desc = "Projects";
        };
      };
    };

    complex = {
      expr =
        let
          luaAction = hax.luaf "vim.diagnostic.goto_next()";
        in
        hax.set "]d" luaAction "Next diagnostic";
      expected = {
        mode = "n";
        key = "]d";
        action = {
          __raw = "function() vim.diagnostic.goto_next() end";
        };
        options = {
          desc = "Next diagnostic";
        };
      };
    };

    invalidType = {
      expr = hax.set "x" 123 "Invalid";
      expectedError.type = "ThrownError";
      expectedError.msg = "type int is invalid for vim keymaps";
    };
  };

  fileGeneration = {
    ftp = {
      expr = hax.files.ftp {
        python = {
          expandtab = true;
          shiftwidth = 4;
        };
        nix = {
          expandtab = true;
          shiftwidth = 2;
        };
      };
      expected = {
        "after/ftplugin/python.lua" = {
          localOpts = {
            expandtab = true;
            shiftwidth = 4;
          };
        };
        "after/ftplugin/nix.lua" = {
          localOpts = {
            expandtab = true;
            shiftwidth = 2;
          };
        };
      };
    };

    injections = {
      expr = hax.files.injections {
        bash = "(comment) @comment";
        python = "(string) @string";
      };
      expected = {
        "after/queries/bash/injections.scm" = {
          text = "(comment) @comment";
        };
        "after/queries/python/injections.scm" = {
          text = "(string) @string";
        };
      };
    };

    textobjects = {
      expr = hax.files.textobjects {
        rust = "@function.outer";
        go = "@block.inner";
      };
      expected = {
        "after/queries/rust/textobjects.scm" = {
          text = "@function.outer";
        };
        "after/queries/go/textobjects.scm" = {
          text = "@block.inner";
        };
      };
    };

    snippets = {
      expr = hax.files.snippets {
        javascript = {
          "console.log" = {
            prefix = "cl";
            body = [ "console.log($1);" ];
            description = "Console log";
          };
        };
      };
      expected = {
        "snippets/javascript.json" = {
          text = ''{"console.log":{"body":["console.log($1);"],"description":"Console log","prefix":"cl"}}'';
        };
      };
    };

    empty = {
      expr = hax.files.ftp { };
      expected = { };
    };

    multiple = {
      expr =
        hax.files.ftp {
          python = {
            tabstop = 4;
          };
          rust = {
            tabstop = 4;
          };
          go = {
            tabstop = 8;
          };
        }
        |> builtins.attrNames
        |> builtins.sort builtins.lessThan;
      expected = [
        "after/ftplugin/go.lua"
        "after/ftplugin/python.lua"
        "after/ftplugin/rust.lua"
      ];
    };
  };
}
