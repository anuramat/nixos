inputs:
(
  final: prev:
  let
    unstable = import inputs.nixpkgs-unstable { inherit (prev) config system; };
  in
  {
    vimPlugins = prev.vimPlugins // {
      inherit (unstable.vimPlugins)
        tinted-nvim
        ;
      avante-nvim = prev.vimPlugins.avante-nvim.overrideAttrs (old: {
        src = inputs.avante;
      });
      blink-cmp-avante = prev.vimPlugins.blink-cmp-avante.overrideAttrs (old: {
        src = inputs.blink-cmp-avante;
      });
    };
  }
)
