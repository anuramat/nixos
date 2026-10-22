# battery charge and time spent in hardware sleep (s0ix) around every sleep, to
# tell what the drain during suspend comes from: `journalctl -t sleep-stats`
{ pkgs, inputs, ... }:
let
  # from this date on, nag on every start of the shell and every unlock to read
  # the logs and drop this module, which removes the reminder with it
  reminder = pkgs.writeShellScript "sleep-stats-reminder" ''
    (($(date +%s) >= $(date -d 2026-10-29 +%s))) || exit 0
    ${pkgs.libnotify}/bin/notify-send -u critical 'sleep-stats: a week of data' \
      'Compare the suspends in `journalctl -t sleep-stats` (see commit e3139df7), then drop nixos-modules/laptop/sleep-stats.nix'
  '';
in
{
  environment.etc."systemd/system-sleep/sleep-stats".source = pkgs.writeShellScript "sleep-stats" ''
    cd /sys/class/power_supply/BAT*
    msg="$1 $2 charge_now=$(<charge_now)uAh"
    [[ $1 == post ]] && msg+=" last_hw_sleep=$(</sys/power/suspend_stats/last_hw_sleep)us"
    ${pkgs.util-linux}/bin/logger -t sleep-stats "$msg"
  '';

  home-manager.users.${inputs.self.consts.user.username}.programs.noctalia.settings.hooks = {
    started = "${reminder}";
    session_unlocked = "${reminder}";
  };
}
