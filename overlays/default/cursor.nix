final: prev:
let
  inherit (prev.lib) splitString;
  inherit (builtins)
    head
    filter
    readFile
    match
    length
    replaceStrings
    ;
in

{
  cursor-agent =
    let
      installer = prev.fetchurl {
        url = "https://cursor.com/install";
        hash = "sha256-sXeflhcWaBo0qoE5wPXiA9ZyT78sRW2UkMiGr13J2Fk=";
      };
      installerText = readFile installer;
      matches =
        splitString "\n" installerText
        |> map (x: x |> match ''DOWNLOAD_URL="(.*)"'')
        |> filter (x: x != null);
      len = length matches;
      linkTemplate =
        if len != 1 then
          throw "cursor-index: ${len} matches for DOWNLOAD_URL in install script:\n\n${installerText}"
        else
          matches |> head |> head;
      link = replaceStrings [ "\${OS}" "\${ARCH}" ] [ "linux" "x64" ] linkTemplate;
      tarball = prev.fetchurl {
        url = link;
        hash = "sha256-046NAHLckWOvIG5WJ8p3SNiUTbelEw2eTZ+/1DvTpNY=";
      };
      version = "nightly";
    in
    prev.stdenv.mkDerivation {
      pname = "cursor-agent";
      inherit version;

      src = tarball;

      nativeBuildInputs = [
        prev.autoPatchelfHook
        prev.stdenv.cc.cc.lib # is this ok? TODO
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin $out/share/cursor-agent
        cp -r * $out/share/cursor-agent/
        ln -s $out/share/cursor-agent/cursor-agent $out/bin/cursor-agent
        runHook postInstall
      '';

      passthru.updateScript = ./update.sh;

      meta = {
        description = "Cursor CLI";
        homepage = "https://cursor.com/cli";
        license = prev.lib.licenses.unfree;
        mainProgram = "cursor-agent";
      };
    };
}
