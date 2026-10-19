{ inputs, ... }:
_final: prev: {
  vimPlugins = prev.vimPlugins // {
    figtree-nvim = inputs.figtree.packages.${prev.stdenv.hostPlatform.system}.default;
    wastebin-nvim = prev.vimUtils.buildVimPlugin {
      pname = "wastebin.nvim";
      version = "nightly";
      src = inputs.wastebin-nvim;
    };
    tree-climber-rust-nvim = prev.vimUtils.buildVimPlugin {
      pname = "tree_climber_rust.nvim";
      version = "nightly";
      src = inputs.tree-climber-rust-nvim;
      dependencies = [ prev.vimPlugins.nvim-treesitter ];
      # nvim-treesitter no longer has ts_utils or parsers.get_parser; inline replacements
      patches = [ ./tree-climber-rust-nvim.patch ];
    };
  };
}
