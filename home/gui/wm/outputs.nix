{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) getExe;
  WSs =
    let
      mkWS =
        # both arguments inclusive.
        # breaks for end > 10.
        start: end:
        let
          mkOne = n: "${toString n}:${lib.mod n 10 |> toString}";
        in
        builtins.genList (n: n + start |> mkOne) (end + 1 - start);
    in
    {
      int = mkWS 1 5;
      ext = mkWS 6 10;
    };

  out = {
    int = "eDP-1";
    ext = [
      "DP-1"
      "DP-2"
      "DP-3"
      "HDMI-A-2"
      "HDMI-A-3"
    ];
  };
in
{
  wayland.windowManager.sway = {
    extraConfig = # sway
      ''
        bindswitch --locked lid:on output ${out.int} disable
        bindswitch --locked lid:off output ${out.int} enable
      '';
    config = {
      workspaceOutputAssign =
        let
          assign =
            output: WSs:
            map (workspace: {
              inherit workspace output;
            }) WSs;
        in
        assign out.int WSs.int ++ assign out.ext WSs.ext;
    };
  };
  services.kanshi = {
    enable = true;
    settings =
      let
        profiles =
          let
            t480 = {
              criteria = "LG Display 0x0521 Unknown";
              position = "0,0";
            };
            ll7 = {
              criteria = "California Institute of Technology 0x1626 0x00006002";
              position = "0,0";
              scale = 1.5;
            };
            home = {
              criteria = "Dell Inc. DELL S2722QC 192SH24";
              scale = 1.5;
              adaptiveSync = false;
            };
            generic = {
              criteria = "*";
              position = "0,-99999";
            };
          in
          {
            # alphabetic priority
            ll7-0 = [
              ll7
            ];
            ll7-1-home = [
              (ll7 // { scale = 2.0; })
              (home // { position = "1600,0"; })
            ];
            ll7-2-generic = [
              ll7
              generic
            ];
            t480-0 = [
              t480
            ];
            t480-1-home = [
              t480
              (home // { position = "0,-2000"; })
            ];
            t480-2-generic = [
              t480
              generic
            ];
          };

        # NOTE that we could've used the output name, if we didn't have the "generic" profile with a wildcard
        moveWSs =
          let
            swaymsg = "${config.wayland.windowManager.sway.package}/bin/swaymsg";
            jq = getExe pkgs.jq;
            grep = getExe pkgs.gnugrep;
            wc = "${pkgs.coreutils}/bin/wc";
          in
          pkgs.writeShellScript "sway_move_workspaces" # bash
            ''
              outputs=$(${swaymsg} -t get_outputs | ${jq} 'map(.name).[]' -r)
              external=$(${grep} -vF "${out.int}" <<< "$outputs")

              ${grep} -qF "${out.int}" <<< "$outputs" || {
                echo "internal output ${out.int} not found"
                exit 1
              }
              n_external=$(${wc} -l <<< "$external")
              (( n_external == 1 )) || {
              	echo "$n_external outputs, expected 2:"
                echo "$outputs"
              	exit 0
              }

              outWSs=(${builtins.concatStringsSep " " WSs.ext})
              focused_ws=$(${swaymsg} -t get_workspaces | ${jq} '.[] | select(.focused == true).name' -r)

              for i in "''${outWSs[@]}"; do
              	${swaymsg} workspace "$i", move workspace to output "$external"
              done
              ${swaymsg} workspace "$focused_ws"
            '';
      in
      lib.mapAttrsToList (n: v: {
        profile = {
          name = n;
          outputs = v;
          exec = [ (toString moveWSs) ];
        };
      }) profiles;
  };
}
