{ pkgs, ... }:
{
  extraPlugins = [
    (
      let
        rev = "002358ab6f0b4696b75905804ea7f1dca34a7ccd";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "tree_climber_rust.nvim";
        version = "nightly";
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "adaszko";
          repo = "tree_climber_rust.nvim";
          sha256 = "0y1y7n1cysplhjpgzhacnk6g7lv2vdvwa5ip0gd8yrlikpzzqfqw";
        };
        postPatch = ''
          substituteInPlace lua/tree_climber_rust.lua \
            --replace-fail 'local ts_utils = require("nvim-treesitter.ts_utils")' '
          local function get_vim_range(range, buf)
              local srow, scol, erow, ecol = unpack(range)
              srow = srow + 1
              scol = scol + 1
              erow = erow + 1
              if ecol == 0 then
                  erow = erow - 1
                  if buf and buf ~= 0 then
                      ecol = #vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
                  else
                      ecol = vim.fn.col { erow, "$" } - 1
                  end
                  ecol = math.max(ecol, 1)
              end
              return srow, scol, erow, ecol
          end

          local function get_node_at_cursor()
              return ts.get_node({ ignore_injections = false })
          end' \
            --replace-fail 'local parsers = require("nvim-treesitter.parsers")' "" \
            --replace-fail 'ts_utils.get_vim_range' 'get_vim_range' \
            --replace-fail 'ts_utils.get_node_at_cursor()' 'get_node_at_cursor()' \
            --replace-fail 'parsers.get_parser(buf):parse()[1]:root()' 'assert(ts.get_parser(buf)):parse()[1]:root()'
        '';
        dependencies = [ pkgs.vimPlugins.nvim-treesitter ];
      }
    )
  ];
}
