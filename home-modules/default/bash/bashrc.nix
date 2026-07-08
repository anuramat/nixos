{
  pkgs,
  config,
  ...
}:
let

  # either orphans or launched with `swaymsg exec`
  orphans = pkgs.writeShellApplication {
    name = "orphans";
    text = # bash
      ''
        ps -o unit,ppid,pid,cmd --ppid 1 | awk '$1=="session-1.scope" {print substr($0, index($0, $3))}'
      '';
  };

  # edit a home-manager link
  hack = pkgs.writeShellApplication {
    name = "hack";
    text = # bash
      ''
        [ -L "$1" ] || {
          echo "$1 is not a symlink"
          exit 1
        }
        mv "$1" "$1.HMLNK"
        cp -L "$1.HMLNK" "$1"
        chmod +w "$1"
        $EDITOR "$1"
      '';
  };

  agenix = config.lib.home.mkAgenixExportScript (t: {
    CACHIX_AUTH_TOKEN = t.cachix;
  });

in

{
  home.packages = [
    orphans
    hack
  ];
  programs.bash.bashrcExtra =
    # bash
    ''
      [[ $- == *i* ]] || return
      # WARN here order matters for sure
      source ${./git.sh}

      source ${./bashrc.sh}

      shopt -s globstar # enables **
      set +H            # turn off ! history bullshit

      # TODO does this even work/is this required
      PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND;}history -a"
      source ${./osc.sh}
      ${agenix}
    '';
}
