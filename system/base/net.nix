{
  lib,
  cluster,
  user,
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
    knownHostsFiles = cluster.hostKeysFiles;
    extraConfig =
      let
        prefix = user.username + "-";
        mkAliasEntry =
          hostname: # ssh_config
          ''
            Host ${lib.strings.removePrefix prefix hostname}
              HostName ${hostname}
          '';
      in
      cluster.hostnames
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
