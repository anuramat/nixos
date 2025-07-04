{ pkgs, config, ... }:
{
  services = {
    swayidle =
      let
        inherit (pkgs)
          swaylock
          sway
          killall
          systemd
          ;

        lockScreen = "${swaylock}/bin/swaylock -f";
        unlockScreen = "${killall}/bin/killall -s USR1 swaylock";

        lockPass =
          let
            gpgLockScript = pkgs.writeShellScript "lockGpgId" ''
              # takes a path to a .gpg-id file, clears the corresponding agent cache
              xargs -r gpg --list-keys --with-colons --with-keygrip < "$1" \
              	| awk -F: '/^sub/{x=1} x&&/^grp/{print $10;x=0}' \
              	| xargs -I{} gpg-connect-agent "clear_passphrase --mode=normal {}" /bye
            '';
          in
          "${gpgLockScript} ${config.programs.password-store.settings.PASSWORD_STORE_DIR}/.gpg-id";
        unlockPass = ''printf '\n\n' | pass insert dummy; pass show dummy'';

        lock = "${lockPass} & ${lockScreen}";
        unlock = "${unlockScreen}; ${unlockPass}";

        screenOff = "${sway}/bin/swaymsg 'output * power off'";
        screenOn = "${sway}/bin/swaymsg 'output * power on'";

        sleep = "${systemd}/bin/systemctl suspend";
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
            command = screenOff;
            resumeCommand = screenOn;
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
