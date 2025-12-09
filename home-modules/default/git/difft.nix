{
  pkgs,
  lib,
  ...
}:
# file navigation with n/p; auto-skip on "-diff" in .gitattributes
let
  invisibleSeparatorEscape = "\\u2063";
  invisibleSeparator = "⁣";
  inherit (lib) getExe;
in
{
  # env var beacuse it's easy to unset for agents
  home.sessionVariables = {
    GIT_EXTERNAL_DIFF = pkgs.writeShellScript "difft" ''
      printf '${invisibleSeparatorEscape}'
      path="$1"
      state=$(${getExe pkgs.git} check-attr diff -- "$path" | ${getExe pkgs.gawk} '{print $3}')
      if [[ $state == "unset" ]]; then
        echo "skipping $path"
        exit 0
      fi
      exec ${getExe pkgs.difftastic} "$@"
    '';
    DFT_SORT_PATHS = "true";
    DFT_IGNORE_COMMENTS = "true";
    DFT_DISPLAY = "inline"; # other option: side-by-side
    DFT_STRIP_CR = "on";
    DFT_TAB_WIDTH = "2";
  };
  programs.less = {
    enable = true;
    config = ''
      J forw-search ${invisibleSeparator}\n
      K back-search ${invisibleSeparator}\n
    '';
  };
  home.packages = [
    pkgs.difftastic
  ];
}
