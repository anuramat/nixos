{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault;
  # interactive plot of the battery history upower keeps for the last 7 days;
  # its history file is named after the battery's model and serial number
  battery-graph = pkgs.writeShellApplication {
    name = "battery-graph";
    runtimeInputs = with pkgs; [
      gawk # strftime
      gnuplot_qt
    ];
    text =
      # bash
      ''
        cd /sys/class/power_supply/BAT*
        {
          echo "\$d << EOD"
          # rows: unix time, percent, state; "unknown" ones are bogus 0% at boot
          awk -F'\t' '$3 != "unknown" { print strftime("%Y-%m-%dT%H:%M:%S", $1) "\t" $2 "\t" $3 }' \
            /var/lib/upower/history-charge-"$(<model_name)"-*"$(<serial_number)".dat
          echo EOD
          cat <<'EOF'
        set terminal qt title "battery"
        set datafile separator "\t"
        set xdata time
        set timefmt "%Y-%m-%dT%H:%M:%S"
        set format x "%a %d\n%H:%M"
        set yrange [0:100]
        set grid
        set key below
        plot $d using 1:2 with lines lc "gray" notitle, \
          "" using 1:(strcol(3) eq "charging" ? $2 : NaN) pt 7 ps 0.4 lc "dark-green" title "charging", \
          "" using 1:(strcol(3) eq "discharging" ? $2 : NaN) pt 7 ps 0.4 lc "red" title "discharging"
        pause mouse close
        EOF
        } | gnuplot
      '';
  };
in
{
  services = {
    thermald.enable = true; # cooling
    logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "lock";
      HandleLidSwitchExternalPower = "lock";
      HoldoffTimeoutSec = 3;
    };
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        CPU_MIN_PERF_ON_AC = mkDefault 50;
        CPU_MAX_PERF_ON_AC = mkDefault 100;
        CPU_MIN_PERF_ON_BAT = mkDefault 0;
        CPU_MAX_PERF_ON_BAT = mkDefault 30;
      };
    };
    upower = {
      enable = true; # sleep on low battery
      usePercentageForPolicy = true;
      percentageCritical = 10;
      criticalPowerAction = "Hibernate";
    };
  };
  environment.systemPackages = [
    battery-graph
    (pkgs.makeDesktopItem {
      name = "battery-graph";
      desktopName = "Battery graph";
      exec = "battery-graph";
      icon = "battery";
    })
  ];
}
