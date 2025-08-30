{ pkgs, lib, ... }:
let
  inherit (pkgs) nbdime;
  inherit (lib) getExe';
in
{
  programs.git = {
    attributes = [
      "*.ipynb diff=jupyternotebook merge=jupyternotebook"
    ];

    extraConfig = {
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
