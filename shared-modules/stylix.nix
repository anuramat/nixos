{
  pkgs,
  inputs,
  ...
}:
{
  stylix = {
    opacity.popups = 0.8;
    cursor = {
      name = "Hackneyed";
      package = pkgs.hackneyed;
      size = 32;
    };
    enable = true;
    fonts = {
      monospace = {
        name = "Monaspace Krypton Frozen";
        package = pkgs.monaspace;
      };
      sizes = {
        applications = 13;
        desktop = 11;
        popups = 11;
        terminal = 13;
      };
      emoji = {
        name = "Noto Emoji";
        package = pkgs.noto-fonts-monochrome-emoji;
      };
    };
    base16Scheme =
      let
        # https://tinted-theming.github.io/tinted-gallery/

        # minimal: black-metal black-metal-venom heetch
        # mono: grayscale-dark grayscale-light greenscreen
        # warm: caroline tarot pandora
        # purple: darkviolet mellow-purple pasque stella
        # cold: tokyo-night-dark moonlight xcode-dusk
        # retro: pop onedark-dark

        # TODO base24:
        # memes: borland unikitty
        # red bg: red-alert red-sands
        # cyberpunk: scarlet-protocol

        # paraiso -- purple/burgundy, colorful text -- 3/5?
        # eris -- navy + pastel red; cyber punk vibes but too much blue -- 4/5
        # outrun-dark -- blue/red, mid
        # pinky -- very colorful, but looks mostly red/blue

        name = "black-metal-venom";
      in
      "${inputs.tt-schemes}/base16/${name}.yaml";
  };
}
