# inline images of typst equations for neovim, cut out of the compiled document
{ lib, ... }:
final: prev:
let
  locked = lib.findFirst (p: p.name == "typst") null (lib.importTOML ./daemon/Cargo.lock).package;
in
{
  # renders with its own typst, which has to be the one that compiles the final document
  typst-eq =
    lib.warnIf (locked.version != final.typst.version)
      "typst-eq is locked to typst ${locked.version}, but typst is ${final.typst.version}"
      final.rustPlatform.buildRustPackage
      {
        pname = "typst-eq";
        inherit ((lib.importTOML ./daemon/Cargo.toml).package) version;
        src = ./daemon;
        cargoLock.lockFile = ./daemon/Cargo.lock;
        nativeBuildInputs = [ final.pkg-config ];
        buildInputs = [ final.openssl ];
        meta.mainProgram = "typst-eq";
      };

  vimPlugins = prev.vimPlugins // {
    typst-eq-nvim = prev.vimUtils.buildVimPlugin {
      pname = "typst-eq.nvim";
      version = "unstable";
      src = ./nvim;
      dependencies = [ prev.vimPlugins.snacks-nvim ];
      postPatch = ''
        substituteInPlace lua/typst-eq/init.lua \
          --replace-fail '{ "typst-eq",' '{ "${lib.getExe final.typst-eq}",'
      '';
      doCheck = true;
      nativeCheckInputs = [
        final.neovim-unwrapped
        final.imagemagick
      ];
      checkPhase = ''
        HOME=$(mktemp -d) SNACKS_GHOSTTY=true nvim -u NONE \
          --cmd "set rtp^=$PWD,${prev.vimPlugins.snacks-nvim},${prev.vimPlugins.nvim-treesitter.grammarPlugins.typst}" \
          -l ${./test.lua}
      '';
    };
  };
}
