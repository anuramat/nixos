{ pkgs, ... }:
{
  stylix = {
    opacity.popups = 0.8;
    polarity = "dark";
    cursor = {
      name = "Hackneyed";
      package = pkgs.hackneyed;
      size = 20;
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
        # stella -- pastel purple bg, otherwise dracula vibes
        # black-metal -- mostly black and white, shades of very faint pastel red and blue otherwise
        # paraiso -- pastel burgundy bg, almost monochrome
        # greenscreen -- green monochrome
        # grayscale-dark -- duh
        # tokyo-night-dark -- colder dracula
        # pandora -- pink/burgundy/red mostly
        # caroline -- warm tones, red/brown
        # digital-rain -- tons of green
        # eris -- navy + pastel red
        # heetch -- red with purple bg
        # tarot -- red, burgundy, purple, kinda like darker heetch
        # saga -- almost b/w
        # onedark-dark -- retro vibes, like elf
        # pasque -- kinda like helix, purple mostly
        # pinky -- very colorful, but looks mostly red/blue
        # pop -- darker elflord kind?
        # windows-nt -- the highest contrast among windowsk, reminds me of elflord
        # shades-of-purple
        # zenbones
        name = "windows-nt";
      in
      "${pkgs.base16-schemes}/share/themes/${name}.yaml";
  };
}
