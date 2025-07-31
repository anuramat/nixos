{ pkgs, inputs, ... }:
{
  stylix = {
    opacity.popups = 0.8;
    cursor = {
      name = "Hackneyed";
      package = pkgs.hackneyed;
      size = 32;
    };
    enable = true;
    autoEnable = true;
    fonts = {
      monospace = {
        name = "Hack Nerd Font";
      };
      sizes = {
        applications = 13;
        desktop = 11;
        popups = 11;
        terminal = 13;
      };
    };
    base16Scheme =
      let
        # black-metal -- almost grayscale -- 5/5; TODO swap green and red
        # grayscale-dark -- grayscale -- 5/5
        # paraiso -- purple/burgundy, colorful text -- 3/5?
        # pandora -- pink/burgundy/red mostly, cyberpunk vibes -- 4/5
        # caroline -- warm tones, red/brown/bronze -- 4/5

        # heetch -- red with purple bg
        # tarot -- red, burgundy, purple, kinda like darker heetch

        # eris -- navy + pastel red
        # pinky -- very colorful, but looks mostly red/blue

        # stella -- pastel purple bg, otherwise dracula vibes
        # pasque -- kinda like helix, purple mostly

        # zenbones -- almost like shuffled dracula
        # tokyo-night-dark -- colder dracula

        # onedark-dark -- retro vibes, like elf
        # pop -- kinda like elf, but darker
        # windows-nt -- the highest contrast among windows, elf kinda

        # xcode-dusk -- grey + bright colors, very cool

        name = "heetch";
      in
      "${inputs.tt-schemes}/base16/${name}.yaml";
  };
}
