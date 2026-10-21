# `battery-graph`: the battery charge history that upower keeps for the last 7
# days, as a page in the browser
{ pkgs, ... }:
let
  uplot = pkgs.fetchzip {
    url = "https://registry.npmjs.org/uplot/-/uplot-1.6.32.tgz";
    hash = "sha256-StSmBUz4natwRi8hXSsQnnjp7xR/7tW58ef0DhjAjxw=";
  };
  battery-graph = pkgs.writeShellApplication {
    name = "battery-graph";
    runtimeInputs = [ pkgs.xdg-utils ];
    text =
      # bash
      ''
        # upower names the history file after the battery's model and serial number
        cd /sys/class/power_supply/BAT*
        page=$XDG_RUNTIME_DIR/battery-graph.html
        {
          cat <<'EOF'
        <!doctype html>
        <meta charset="utf-8">
        <title>battery</title>
        <link rel="stylesheet" href="${uplot}/dist/uPlot.min.css">
        <style>html, body { margin: 0; overflow: hidden; }</style>
        <body>
        <script src="${uplot}/dist/uPlot.iife.min.js"></script>
        <script>const rows = [
        EOF
          # rows: unix time, percent, state; "unknown" ones are bogus 0% at boot
          awk -F'\t' '$3 != "unknown" { printf "%s[%s,%s,\"%s\"]", sep, $1, $2, $3; sep = "," }' \
            /var/lib/upower/history-charge-"$(<model_name)"-*"$(<serial_number)".dat
          echo '];</script>'
          echo '<script src="${./battery-graph.js}"></script>'
        } >"$page"
        xdg-open "$page"
      '';
  };
in
{
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
