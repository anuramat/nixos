{
  pkgs,
  lib,
  ...
}:
{
  programs = {
    starship = {
      enable = true;
      presets = [ "plain-text-symbols" ];
      settings = {
        format = " $all$status$line_break$character";
        character = {
          success_symbol = "";
          error_symbol = "";
          vimcmd_symbol = "";
        };
        status = {
          disabled = false;
          style = "bold red";
          format = "[$status:$common_meaning$signal_name]($style)";
        };
        time = {
          disabled = false;
          format = "[$time]($style) ";
        };
        username.disabled = true;
        battery.disabled = true;
      };
    };

    direnv = {
      enable = true;
      silent = true;
      # direnvrcExtra = ''
      # '';
    };

    fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };

    bash = {
      shellAliases = lib.mkForce { };
      promptInit = "# placeholder: bash.promptInit";
      enableLsColors = false;
      shellInit = "# placeholder: bash.shellInit";
      loginShellInit = "# placeholder: bash.loginShellInit";
      interactiveShellInit = ''
        # bash.interactiveShellInit {{{1
        source ${./osc.sh}
        source ${./history.sh}
        source ${pkgs.bash-preexec}/share/bash/bash-preexec.sh
        # end }}}
      '';
    };
  };

  # exec order:
  # /etc/profile: bash.shellInit, shellInit, bash.loginShellInit, loginShellInit, /etc/profile.local, /etc/bashrc
  # /etc/bashrc: /etc/profile, bash.interactiveShellInit, bash.promptInit, (?hooks from software options?), interactiveShellInit, /etc/bashrc.local

  environment = {
    shellAliases = lib.mkForce { };
    shellInit = "# placeholder: environment.shellInit";
    loginShellInit = ''
      # placeholder: environment.loginShellInit {{{1
      source ${./profile.sh}
      source ${./sway_autostart.sh}
      # end }}}
    '';
    interactiveShellInit = "# placeholder: environment.interactiveShellInit";
    extraInit = "# placeholder: environment.extraInit";
  };
}
# vim: fdl=3
