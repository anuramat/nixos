{ pkgs, ... }:
{
  fonts.fontconfig = {
    enable = true;
    # emoji font is monochrome; otherwise fontconfig ranks any color font (e.g. rnote's OpenDyslexic) above it
    configFile.mono-emoji = {
      enable = true;
      text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <match>
            <test name="lang"><string>und-zsye</string></test>
            <edit name="color"><bool>false</bool></edit>
          </match>
        </fontconfig>
      '';
    };
  };
  home.packages = with pkgs; [
    fira-code
    fira-code-symbols
    iosevka
    monaspace
    nerd-fonts.symbols-only
  ];
}
