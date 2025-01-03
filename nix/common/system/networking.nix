{ user, ... }:
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

  users.users.${user.username}.openssh.authorizedKeys.keys = user.keys;

  services = {
    fail2ban.enable = true; # intrusion prevention
    tailscale.enable = true;
    openssh = {
      enable = true;
      ports = [ 22 ];
      knownHosts = user.knownHosts;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        PrintLastLog = false;
        AllowUsers = [ user.username ];
      };
    };
  };
}
