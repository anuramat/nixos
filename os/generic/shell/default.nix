{
  pkgs,
  lib,
  ...
}:
{
  # login exec order:
  # - /etc/profile: bash.shellInit, shellInit, bash.loginShellInit, loginShellInit, /etc/profile.local, /etc/bashrc
  #   - where /etc/bashrc: /etc/profile, bash.interactiveShellInit, bash.promptInit, (?hooks from software options?), interactiveShellInit, /etc/bashrc.local

  # TODO move to hm
  programs = {
    bash = {
      interactiveShellInit = # bash
        ''
          # bash.interactiveShellInit {{{1
          source ${./osc.sh}
          source ${./history.sh}
          source ${pkgs.bash-preexec}/share/bash/bash-preexec.sh
          # end }}}
        '';
    };
  };

  environment = {
    shellAliases = lib.mkForce { };
    loginShellInit = # sh
      ''
        # placeholder: environment.loginShellInit {{{1
        source ${./profile.sh}
        # end }}}
      '';
  };
}
# vim: fdl=3
