{
  lib,
  config,
  ...
}:
{
  networking = {
    firewall = {
      enable = true;
    };
    networkmanager = {
      enable = true;
    };
  };

  services.resolved = {
    enable = true;
    # dnssec = "true"; # TODO breaks sometimes, try again with captive
  };

  programs.ssh = {
    inherit (config.lib.hosts) knownHostsFiles;
    extraConfig =
      let
        prefix = config.userConfig.username + "-";
        mkAliasEntry =
          hostname: # ssh_config
          ''
            Host ${lib.strings.removePrefix prefix hostname}
              HostName ${hostname}
          '';
      in
      (builtins.attrNames config.lib.hosts.hosts)
      |> lib.filter (x: lib.strings.hasPrefix prefix x)
      |> map mkAliasEntry
      |> lib.strings.intersperse "\n"
      |> lib.concatStrings;
  };
  services = {
    fail2ban.enable = true; # intrusion prevention
    tailscale.enable = true;
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        PrintLastLog = false;
      };
    };
  };
}
