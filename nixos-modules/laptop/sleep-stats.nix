# battery charge and time spent in hardware sleep (s0ix) around every sleep, to
# tell what the drain during suspend comes from: `journalctl -t sleep-stats`
{ pkgs, ... }:
{
  environment.etc."systemd/system-sleep/sleep-stats".source = pkgs.writeShellScript "sleep-stats" ''
    cd /sys/class/power_supply/BAT*
    msg="$1 $2 charge_now=$(<charge_now)uAh"
    [[ $1 == post ]] && msg+=" last_hw_sleep=$(</sys/power/suspend_stats/last_hw_sleep)us"
    ${pkgs.util-linux}/bin/logger -t sleep-stats "$msg"
  '';
}
