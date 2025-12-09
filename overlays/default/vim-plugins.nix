inputs:
(
  _: prev:
  let
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev) config;
      inherit (prev.stdenv.hostPlatform) system;
    };
  in
  {
    vimPlugins = prev.vimPlugins // {
      inherit (unstable.vimPlugins)
        tinted-nvim
        rustaceanvim
        ;
      avante-nvim = prev.vimPlugins.avante-nvim.overrideAttrs (_: {
        src = inputs.avante;
      });
      blink-cmp-avante = prev.vimPlugins.blink-cmp-avante.overrideAttrs (_: {
        src = inputs.blink-cmp-avante;
      });
    };
  }
)
