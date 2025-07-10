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
        screen =
          let
            swaymsg = "${pkgs.sway}/bin/swaymsg";
          in
          {
            off = "${swaymsg} 'output * power off'";
            on = "${swaymsg} 'output * power on'";
          };
        lock =
          let
            screen = "${lib.getExe pkgs.swaylock} -f";
            pass =
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
          in
          "${pass} && ${screen}";
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
        ];
        events = [
          {
            event = "before-sleep";
            command = lock;
          }
          {
            event = "lock";
            command = lock;
          }
        ];
      };
  };
}
