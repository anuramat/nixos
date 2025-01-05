{
  config,
  cluster,
  ...
}:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true; # bluetooth gui

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        8080
        8888
        5000 # nix-serve
      ];
      allowedUDPPorts = [ ];
    };
    networkmanager = {
      enable = true;
    };
  };

  users.users.${config.me}.openssh.authorizedKeys = {
    keys = cluster.miscKeys;
    keyFiles = cluster.clientKeyFiles;
  };

  programs.ssh.knownHostsFiles = cluster.hostKeysFiles;
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
        AllowUsers = [ config.me ];
      };
    };
  };
}
