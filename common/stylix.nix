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
        # black-metal -- mostly black and white, shades of very faint pastel red and blue otherwise
        # saga -- almost b/w
        # grayscale-dark -- duh

        # greenscreen -- green monochrome
        # digital-rain -- tons of green

        # paraiso -- pastel burgundy bg, almost monochrome
        # pandora -- pink/burgundy/red mostly
        # caroline -- warm tones, red/brown
        # heetch -- red with purple bg
        # tarot -- red, burgundy, purple, kinda like darker heetch

        # eris -- navy + pastel red
        # pinky -- very colorful, but looks mostly red/blue

        # stella -- pastel purple bg, otherwise dracula vibes
        # pasque -- kinda like helix, purple mostly
        # shades-of-purple -- like colorful helix

        # zenbones -- almost like shuffled dracula
        # tokyo-night-dark -- colder dracula

        # onedark-dark -- retro vibes, like elf
        # pop -- kinda like elf, but darker
        # windows-nt -- the highest contrast among windows, elf kinda

        # xcode-dusk -- grey + bright colors, very cool

        name = "base16/saga";
      in
      "${inputs.tt-schemes}/${name}.yaml";
  };
}
