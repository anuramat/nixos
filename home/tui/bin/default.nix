{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (pkgs) writeShellApplication writeScriptBin;
  inherit (builtins) readFile readDir;

  packages =
    with lib;
    readDir ./.
    |> attrNames
    |> map (
      filename:
      let
        text = readFile ./${filename};
        name = removeSuffix ("." + ext) filename;
        ext = filename |> splitString "." |> last;
      in
      if ext == "sh" then
        writeShellApplication {
          inherit name text;
          excludeShellChecks = map (v: "SC" + toString v) config.lib.excludeShellChecks.numbers;
        }
      else
        writeScriptBin name text
    );
in
{
  home.packages = packages;
}
