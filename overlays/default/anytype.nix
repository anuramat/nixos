final: prev: {
  anytype = prev.appimageTools.wrapType2 rec {
    pname = "anytype";
    version = "0.49.2";
    src = prev.fetchurl {
      url = "https://github.com/anyproto/anytype-ts/releases/download/v${version}/Anytype-${version}.AppImage";
      hash = "sha256-NA8PozwenoIClkWry1q1Z/crhieflrlJVtBLLrKwWEk=";
    };
    extraInstallCommands =
      # XXX vibecoded
      let
        appimageContents = prev.appimageTools.extractType2 {
          inherit pname version src;
        };
      in
      # bash
      ''
        # Install desktop file
        install -Dm644 ${appimageContents}/anytype.desktop $out/share/applications/${pname}.desktop
        # Install icon (use the main icon)
        install -Dm644 ${appimageContents}/anytype.png $out/share/pixmaps/${pname}.png
        # Install hicolor icons
        cp -r ${appimageContents}/usr/share/icons $out/share/
        # Fix desktop file Exec path
        substituteInPlace $out/share/applications/${pname}.desktop --replace-fail 'Exec=AppRun' 'Exec=${pname}'
      '';
    meta = prev.anytype.meta;
  };
}
