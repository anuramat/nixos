{ pkgs, ... }:
let
  ryzenadj = "${pkgs.ryzenadj}/bin/ryzenadj";
  awk = "${pkgs.gawk}/bin/awk";
  ecBase = "/sys/class/ec_su_axb35";

  # five temps for 20% fan speed increments
  profiles = {
    default = {
      tctlTemp = 95;
      rampupCurve = "35,50,60,85,90";
      rampdownCurve = "0,45,55,70,85";
    };
    quiet = {
      tctlTemp = 75;
      rampupCurve = "35,80,85,88,90";
      rampdownCurve = "0,75,80,83,85";
    };
  };

  # runtime toggle for the profiles above; run with sudo
  bgm5powerctl = pkgs.writeShellScriptBin "bgm5powerctl" ''
    set -euo pipefail

    verify_attr() {
      local path=$1 expected=$2 actual
      actual=$(<"$path")
      if [ "$actual" != "$expected" ]; then
        echo "verify failed for $path: expected '$expected', got '$actual'" >&2
        exit 1
      fi
    }

    require_fans() {
      local path
      [ -d ${ecBase} ] || { echo "${ecBase} is not available" >&2; exit 1; }
      for f in fan1 fan2; do
        for attr in mode rampup_curve rampdown_curve; do
          path=${ecBase}/$f/$attr
          [ -w "$path" ] || { echo "$path is not writable" >&2; exit 1; }
        done
      done
    }

    apply_tctl() {
      local tctl=$1 actual
      ${ryzenadj} --tctl-temp="$tctl"
      actual=$(${ryzenadj} -i | ${awk} -F'|' '/[|] THM LIMIT CORE/ { gsub(/ /, "", $3); split($3, v, "."); print v[1]; exit }')
      if [ "$actual" != "$tctl" ]; then
        echo "tctl verify failed: expected $tctl, got $actual" >&2
        exit 1
      fi
    }

    apply_fans() {
      local rampup=$1 rampdown=$2
      for f in fan1 fan2; do
        echo curve > ${ecBase}/"$f"/mode
        echo "$rampup" > ${ecBase}/"$f"/rampup_curve
        echo "$rampdown" > ${ecBase}/"$f"/rampdown_curve
        verify_attr ${ecBase}/"$f"/mode curve
        verify_attr ${ecBase}/"$f"/rampup_curve "$rampup"
        verify_attr ${ecBase}/"$f"/rampdown_curve "$rampdown"
      done
    }

    case "''${1:-}" in
    default)
      require_fans
      apply_fans "${profiles.default.rampupCurve}" "${profiles.default.rampdownCurve}"
      apply_tctl ${toString profiles.default.tctlTemp}
      ;;
    quiet)
      require_fans
      apply_tctl ${toString profiles.quiet.tctlTemp}
      apply_fans "${profiles.quiet.rampupCurve}" "${profiles.quiet.rampdownCurve}"
      ;;
    *)
      echo "usage: bgm5powerctl default|quiet" >&2
      exit 1
      ;;
    esac
    echo "bgm5powerctl: applied ''$1"
  '';
in
{
  environment.systemPackages = [ bgm5powerctl ];
  powerManagement.cpuFreqGovernor = "powersave";
  services = {
    ryzenadj = {
      enable = true;
      inherit (profiles.default) tctlTemp;
    };
    ec-su-axb35 = {
      enable = true;
      monitor.enable = true;
      powerMode = "quiet";
      fans = {
        fan1 = {
          mode = "curve"; # default: auto
          inherit (profiles.default) rampupCurve rampdownCurve;
          # defaults:
          # rampupCurve = "60,70,83,95,97";
          # rampdownCurve = "40,50,80,94,96";
        };
        fan2 = {
          mode = "curve"; # default: curve
          inherit (profiles.default) rampupCurve rampdownCurve;
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
