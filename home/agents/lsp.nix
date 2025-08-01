{
  lib,
  config,
  pkgs,
  ...
}:
let
  servers =
    with config.programs.nixvim.plugins.lsp.servers;
    {
      go = gopls;
      nix = nil_ls;
      python = pyright;
    }
    |> filterAttrs (n: v: v.enable)
    |> mapAttrs (
      n: v: {
        command = getExe v.package;
        args = if v.cmd == null then [ ] else tail v.cmd;
        options = v.settings;
      }
    );
  name = "lsp_settings.json";
in
{
  lib.agents.lsp = config.lib.home.mkJson name servers;
}
