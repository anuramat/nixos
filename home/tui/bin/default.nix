{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) writeShellApplication writeScriptBin;
  inherit (builtins) readFile;

  collect = writeShellApplication {
    name = "collect";
    text = readFile ./collect.sh;
  };

  packages =
    with lib;
    readDir ./.
    |> attrNames
    |> map (
      filename:
      let
        text = readFile ./${filename};
        name = removeSuffix ("." + ext) filename;
        ext = name |> splitString "." |> last;
      in
      if ext == "sh" then
        pkgs.writeShellApplication {
          inherit name text;
        }
      else
        writeScriptBin name text
    );

  rs = writeShellApplication {
    name = "rs";
    text = readFile ./rs.sh;
    runtimeInputs = with pkgs; [
      rsync
    ];
  };
  todo = writeScriptBin "todo" (readFile ./todo.py);
in
{
  home.packages = packages;
}
