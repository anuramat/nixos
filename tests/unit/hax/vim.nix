{ pkgs, lib }:
let
  hax = import ../../../hax/vim.nix { inherit lib; };
in
{
  # Test lua helper
  testLua = {
    expr = hax.lua "vim.cmd('echo')";
    expected = {
      __raw = "vim.cmd('echo')";
    };
  };

  # Test luaf helper (wrapped in function)
  testLuaf = {
    expr = hax.luaf "return 42";
    expected = {
      __raw = "function() return 42 end";
    };
  };

  # Test set with string action
  testSetString = {
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

  # Test set with string action and empty description
  testSetStringNoDesc = {
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

  # Test set with raw lua action (set type)
  testSetLuaAction = {
    expr =
      hax.set "<leader>p" (hax.lua "require('telescope').extensions.projects.projects()")
        "Projects";
    expected = {
      mode = "n";
      key = "<leader>p";
      action = {
        __raw = "require('telescope').extensions.projects.projects()";
      };
      options = {
        desc = "Projects";
      };
    };
  };

  # Test set with invalid action type
  testSetInvalidType = {
    expr = hax.set "x" 123 "Invalid";
    expectedError.type = "ThrownError";
    expectedError.msg = "type int is invalid for vim keymaps";
  };

  # Test files.ftp
  testFilesFtp = {
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

  # Test files.injections
  testFilesInjections = {
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

  # Test files.textobjects
  testFilesTextobjects = {
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

  # Test files.snippets
  testFilesSnippets = {
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

  # Test complex keymap scenario
  testComplexKeymap = {
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

  # Test files with empty input
  testFilesEmpty = {
    expr = hax.files.ftp { };
    expected = { };
  };

  # Test multiple file types in one call
  testFilesMultiple = {
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
}
