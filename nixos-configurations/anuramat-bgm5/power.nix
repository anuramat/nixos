{
  powerManagement.cpuFreqGovernor = "powersave";
  services = {
    tuned = {
      enable = false;
      # TODO: enable, make default profile repeat whatever we already have, add a custom quieter profile for gpu runs at night
    };
    ryzenadj = {
      enable = true;
      tctlTemp = 45;
    };
    ec-su-axb35 = {
      enable = true;
      monitor.enable = true;
      powerMode = "quiet";
      fans =
        let
          rampupCurve = "35,50,60,85,90";
          rampdownCurve = "0,45,55,70,85";
        in
        {
          fan1 = {
            mode = "curve"; # default: auto
            inherit rampupCurve rampdownCurve;
            # defaults:
            # rampupCurve = "60,70,83,95,97";
            # rampdownCurve = "40,50,80,94,96";
          };
          fan2 = {
            mode = "curve"; # default: curve
            inherit rampupCurve rampdownCurve;
            # defaults:
            # rampupCurve = "60,70,83,95,97";
            # rampdownCurve = "40,50,80,94,96";
          };
          fan3 = {
            mode = "auto"; # default: auto
            # defaults:
            # rampupCurve = "20,60,83,95,97";
            # rampdownCurve = "0,50,80,94,96";
          };
        };
    };
  };
}
