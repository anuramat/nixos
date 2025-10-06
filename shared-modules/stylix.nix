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
        # favs: black-metal tarot
        # mono: grayscale-dark grayscale-light greenscreen
        # warm: mellow-purple uwunicorn pasque stella
        # cold: moonlight
        # retro: onedark-dark pop windows-*
        # grey: xcode-dusk tokyo-night-dark
        # TODO base24: borland mona-lisa red-alert red-sands unikitty

        # paraiso -- purple/burgundy, colorful text -- 3/5?
        # pandora -- pink/burgundy/red mostly, cyberpunk vibes -- 4/5
        # caroline -- warm tones, red/brown/bronze; very cozy -- 4/5
        # tarot -- red, burgundy, purple; cyberpunk vibes  -- 5/5
        # eris -- navy + pastel red; cyber punk vibes but too much blue -- 4/5
        # outrun-dark -- blue/red, mid
        # heetch -- red + blue, cool but kinda unreadable
        # pinky -- very colorful, but looks mostly red/blue

        name = "tarot";
      in
      "${inputs.tt-schemes}/base16/${name}.yaml";
  };
}
