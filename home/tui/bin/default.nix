{
  pkgs,
  ...
}:
let
  inherit (pkgs) writeShellApplication writeScriptBin;
  inherit (builtins) readFile;

  collect = writeShellApplication {
    name = "collect";
    text = readFile ./collect.sh;
  };

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
  home.packages = [
    rs
    todo
    collect
  ];
}
