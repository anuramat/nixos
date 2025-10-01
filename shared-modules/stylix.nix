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
        # black-metal -- almost grayscale -- 5/5; TODO swap green and red
        # black-metal-*
        # grayscale-dark
        # grayscale-light
        # greenscreen
        # paraiso -- purple/burgundy, colorful text -- 3/5?
        # pandora -- pink/burgundy/red mostly, cyberpunk vibes -- 4/5
        # caroline -- warm tones, red/brown/bronze; very cozy -- 4/5
        # tarot -- red, burgundy, purple; cyberpunk vibes  -- 5/5
        # eris -- navy + pastel red; cyber punk vibes but too much blue -- 4/5

        # outrun-dark -- blue/red, mid
        # heetch -- red + blue, cool but kinda unreadable
        # pinky -- very colorful, but looks mostly red/blue

        # mellow-purple --  blue/purple, cute, but comments are unreadable
        # pasque -- kinda like helix, purple mostly
        # stella -- pastel purple bg, otherwise dracula vibes
        # moonlight -- dracula but mostly blue
        # tokyo-night-dark -- colder dracula
        # zenbones -- almost like shuffled dracula

        # onedark-dark -- retro vibes, like elf
        # pop -- kinda like elf, but darker
        # windows-nt -- the highest contrast among windows, elf kinda

        # xcode-dusk -- grey + bright colors, very cool

        # uwunicorn
        # aztec

        # TODO base24
        # borland
        # mona-lisa

        name = "windows-nt";
      in
      "${inputs.tt-schemes}/base16/${name}.yaml";
  };
}
