{ unstable, ... }:
{
  fonts = {
    packages = with unstable; [
      nerd-fonts.hack
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term
      nerd-fonts.fira-mono
      nerd-fonts.fira-code
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "Hack Nerd Font" ];
      };
    };
  };
}
