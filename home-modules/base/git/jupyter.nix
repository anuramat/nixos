{ pkgs, lib, ... }:
let
  inherit (lib) getExe';
  inherit (pkgs.python3Packages) nbdime; # ipynb diff, merge
in
{
  home.packages = [
    nbdime
  ];
  programs.git = {
    attributes = [
      "*.ipynb diff=jupyternotebook merge=jupyternotebook"
    ];

    settings = {
      diff.jupyternotebook.command = # bash
        "${getExe' nbdime "git-nbdiffdriver"} diff";
      merge.jupyternotebook = {
        driver = # bash
          "${getExe' nbdime "git-nbmergedriver"} merge %O %A %B %L %P";
        name = "jupyter notebook merge driver";
      };
      difftool.nbdime.cmd = # bash
        ''${getExe' nbdime "git-nbdifftool"} diff "$LOCAL" "$REMOTE" "$BASE"'';
      mergetool.nbdime.cmd = # bash
        ''${getExe' nbdime "git-nbmergetool"} merge "$BASE" "$LOCAL" "$REMOTE" "$MERGED"'';
    };
  };
}
