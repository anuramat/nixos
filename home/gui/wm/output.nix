{ lib, pkgs, ... }:
let
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
        assign out.int WSs.int ++ assign out.ext WSs.out;
    };
  };
  services.kanshi = {
    enable = true;
    extraConfig =
      let
        moveWSs =
          pkgs.writeShellScript "move_workspaces" # bash
            ''
              internal="${out.int}"
              external=$(swaymsg -t get_outputs | jq 'map(.name).[]' -r | grep -vF "$internal")
              [[ $(wc -l <<< "$external") == 1 ]] || {
              	echo "more than one external output connected, exiting"
              	exit 0
              }

              outWSs=(${builtins.concatStringsSep " " WSs.out})
              focused_ws=$(swaymsg -t get_workspaces | jq '.[] | select(.focused == true).name' -r)

              for i in "''${outWSs[@]}"; do
              	swaymsg workspace "$i", move workspace to output "$external"
              done
              swaymsg workspace "$focused_ws"
            '';
      in
      "exec ${moveWSs}";
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
            };
          in
          {
            ll7 = [
              ll7
            ];
            ll7-home = [
              (ll7 // { scale = 2.0; })
              (home // { position = "1600,0"; })
            ];
            ll7-generic = [
              ll7
              (generic // { position = "0,-2000"; })
            ];
            t480 = [
              t480
            ];
            t480-home = [
              t480
              (home // { position = "0,-2000"; })
            ];
          };
      in
      lib.mapAttrsToList (n: v: {
        profile = {
          name = n;
          outputs = v;
        };
      }) profiles;
  };
}
