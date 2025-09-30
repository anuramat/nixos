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

        # pinky -- very colorful, but looks mostly red/blue

        # stella -- pastel purple bg, otherwise dracula vibes
        # pasque -- kinda like helix, purple mostly

        # zenbones -- almost like shuffled dracula
        # tokyo-night-dark -- colder dracula

        # onedark-dark -- retro vibes, like elf
        # pop -- kinda like elf, but darker
        # windows-nt -- the highest contrast among windows, elf kinda

        # xcode-dusk -- grey + bright colors, very cool

        # outrun-dark -- blue/red, mid
        # uwunicorn
        # moonlight
        # mona-lisa
        # mellow-purple --  blue/purple, cute, but comments are unreadable
        # heetch # red + blue, cool but kinda unreadable

        # TODO base24
        # borland

        name = "mona-lisa";
      in
      "${inputs.tt-schemes}/base16/${name}.yaml";
  };
}
