{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) getExe range;
  WSs =
    let
      mkOne = n: "${toString n}:${lib.mod n 10 |> toString}";
    in
    {
      int = range 1 5 |> map mkOne;
      ext = range 6 10 |> map mkOne;
    };
  out = {
    int = "eDP-1";
    ext = [
      "DP-1"
      "DP-2"
      "DP-3"
      "DP-4"
      "HDMI-A-2"
      "HDMI-A-3"
      "HEADLESS-1"
    ];
  };

  reloadKanshi = [
    {
      # <https://github.com/nix-community/home-manager/issues/2797>
      command = "${pkgs.kanshi}/bin/kanshictl reload";
      always = true;
    }
  ];

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
{
  wayland.windowManager.sway = {
    extraConfig = # sway
      ''
        bindswitch --locked lid:on output ${out.int} disable
        bindswitch --locked lid:off output ${out.int} enable
      '';
    config = {
      startup = reloadKanshi;

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
  services.kanshi.exec = [
    (toString moveWSs)
  ];
}
