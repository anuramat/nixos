{
  pkgs,
  config,
  lib,
  ...
}:
# file navigation with n/p; auto-skip on "-diff" in .gitattributes
let
  invisibleSeparator = "\\u2063";
  inherit (lib) getExe;
in
{
  # env var beacuse it's easy to unset for agents
  home.sessionVariables.GIT_EXTERNAL_DIFF = pkgs.writeShellScript "difft" ''
    printf '${invisibleSeparator}'
    path="$1"
    state=$(${getExe pkgs.git} check-attr diff -- "$path" | ${getExe pkgs.gawk} '{print $3}')
    if [[ $state == "unset" ]]; then
      echo "skipping $path"
      exit 0
    fi
    exec ${getExe pkgs.difftastic} --display inline --background dark "$@"
  '';
  programs.git.extraConfig.core.pager = pkgs.writeShellScript "less-difft" ''
    exec less -rp $'${invisibleSeparator}' "$@"
  '';
}
