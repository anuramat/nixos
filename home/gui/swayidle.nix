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
        bin = {
          systemctl = "${pkgs.systemd}/bin/systemctl";
          swaymsg = "${pkgs.sway}/bin/swaymsg";
          killall = lib.getExe pkgs.killall;
          swaylock = "${pkgs.swaylock}/bin/swaylock";
        };

        screen = {
          lock = "${bin.swaylock} -f";
          unlock = "${bin.killall} -s USR1 swaylock";
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
                  xargs -r gpg --list-keys --with-colons --with-keygrip < "$1" \
                  	| awk -F: '/^sub/{x=1} x&&/^grp/{print $10;x=0}' \
                  	| xargs -I{} gpg-connect-agent "clear_passphrase --mode=normal {}" /bye
                '';
              };
            in
            "${lib.getExe gpg-lock} ${config.programs.password-store.settings.PASSWORD_STORE_DIR}/.gpg-id";
          unlock = ''printf '\n\n' | pass insert dummy; pass show dummy'';
        };

        lock = "${pass.lock} & ${screen.lock}";
        unlock = "${screen.unlock}; ${pass.unlock}";
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
