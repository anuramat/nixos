{ config, pkgs, ... }:
{
  home.packages = [ pkgs.rustdesk-flutter ]; # remote desktop client

  # rustdesk rewrites its config at runtime, so seed the real file instead of
  # symlinking. The dead rendezvous server keeps it off the public infra; we
  # connect over the tailnet with direct IP access instead. direct-server only
  # takes effect where the rustdesk service runs (bgm5).
  home.activation.rustdeskConfig =
    config.lib.home.mkGenericActivationScript
      (pkgs.writeText "RustDesk2.toml" ''
        [options]
        custom-rendezvous-server = '127.0.0.1'
        direct-server = 'Y'
      '')
      "${config.xdg.configHome}/rustdesk/RustDesk2.toml";
}
