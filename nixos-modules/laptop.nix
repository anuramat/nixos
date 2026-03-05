{
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  thermald.enable = true; # cooling
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
}
