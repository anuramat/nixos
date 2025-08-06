{ lib, pkgs, ... }:
let
  port = toString 4141;
  pkg = pkgs.copilot-api-go;
in
{
  lib.agents.api.port = port;
  systemd.user.services.copilot-api =
    let
      target = "network.target";
    in
    {
      Unit = {
        Description = "copilot-api server";
        After = [ target ]; # enforces order, does not imply dependency
        PartOf = [ target ]; # propagates stop and restart
        Requries = [ target ]; # dependency
      };
      Service = {
        ExecStart = "${lib.getExe' pkg "copilot-api"} start -p ${port}";
        Restart = "no";
      };
    };
}
