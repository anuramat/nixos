{ lib, ... }:
let
  internal = "eDP-1";
  externals = builtins.concatStringsSep " " [
    "DP-1"
    "DP-2"
    "DP-3"
    "HDMI-A-2"
  ];

  mod = x: y: y - x * (builtins.div y x); # TODO lib

  mkAssign =
    output: numbers:
    map (n: {
      workspace = "${toString n}:${n |> mod 10 |> toString}";
      output = output;
    }) numbers;

in
{
  wayland.windowManager.sway.config.workspaceOutputAssign =

    mkAssign internal [
      1
      2
      3
      4
      5
    ]
    ++ mkAssign externals [
      6
      7
      8
      9
      10
    ];
}
