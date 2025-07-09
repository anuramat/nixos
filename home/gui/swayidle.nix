{
  pkgs,
  config,
  lib,
  ...
}:
{
  services = {
    swayidle =
      let
        bin = with pkgs; {
          systemctl = "${systemd}/bin/systemctl";
          swaymsg = "${sway}/bin/swaymsg";
          pkill = "${procps}/bin/pkill";
          swaylock = lib.getExe swaylock;
        };

        screen = {
          lock = "${bin.swaylock}";
          unlock = "${bin.pkill} -USR1 -f '^${bin.swaylock}'";
          off = "${bin.swaymsg} 'output * power off'";
          on = "${bin.swaymsg} 'output * power on'";
        };

        pass = {
          lock =
            let
              gpg-lock = pkgs.writeShellApplication {
                name = "gpg-lock";
                runtimeInputs = with pkgs; [
                  gnupg # gpg and gpg-connect-agent
                  gawk # awk
                  findutils # xargs
                ];
                text = ''
                  # takes a path to a .gpg-id file, clears the corresponding agent cache
                  GNUPGHOME=${config.programs.gpg.homedir}
                  export GNUPGHOME
                  xargs -r gpg --list-keys --with-colons --with-keygrip < "$1" \
                  	| awk -F: '/^sub/{x=1} x&&/^grp/{print $10;x=0}' \
                  	| xargs -I{} gpg-connect-agent "clear_passphrase --mode=normal {}" /bye
                '';
              };
            in
            "${lib.getExe gpg-lock} ${config.programs.password-store.settings.PASSWORD_STORE_DIR}/.gpg-id";
        };

        lock = "${pass.lock} && ${screen.lock}";
        unlock = "${screen.unlock}";
        sleep = "${bin.systemctl} suspend";
      in
      {
        enable = true;
        # idlehint = 300; # TODO implement/beg
        # BUG duplicate events overwrite previous definitions: <https://github.com/nix-community/home-manager/issues/4432>
        timeouts = [
          {
            timeout = 300;
            command = lock;
          }
          {
            timeout = 600;
            command = screen.off;
            resumeCommand = screen.on;
          }
          {
            timeout = 999999;
            command = sleep;
          }
        ];
        events = [
          {
            event = "before-sleep";
            command = lock;
          }
          {
            event = "unlock";
            command = unlock;
          }
          {
            event = "lock";
            command = lock;
          }
        ];
      };
  };
}
