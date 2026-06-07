{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.age) secrets;
in
{
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        12345
      ];
    };
    networkmanager = {
      enable = true;
    };
  };
  networking.openconnect.interfaces.uhd = {
    autoStart = true;
    gateway = "vpn-ac.urz.uni-heidelberg.de";
    user = "un330";
    protocol = "anyconnect";
    passwordFile = secrets.hdpw.path;
    extraOptions = {
      token-mode = "totp";
      token-secret = "@${secrets.hdotp.path}";
      script = "${pkgs.vpn-slice}/bin/vpn-slice --no-host-names --no-ns-hosts bwunicluster.scc.kit.edu 129.206.0.0/16 147.142.0.0/16";
    };
  };
  environment.systemPackages = with pkgs; [
    networkmanager-openconnect
  ];

  services.resolved = {
    enable = true;
    # dnssec = "true"; # TODO breaks sometimes, try again with captive
  };

  programs.ssh = {
    inherit (config.lib.hosts) knownHostsFiles;
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
