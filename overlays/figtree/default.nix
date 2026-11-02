# figlet startup banner for neovim
_: _final: prev: {
  vimPlugins = prev.vimPlugins // {
    figtree-nvim = prev.vimUtils.buildVimPlugin {
      pname = "figtree.nvim";
      version = "unstable";
      src = ./.;
      postPatch = ''
        substituteInPlace lua/figtree/io.lua \
          --replace-fail "'figlet'," "'${prev.figlet}/bin/figlet',"
      '';
    };
  };
}
