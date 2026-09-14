{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.age) secrets;
  inherit (inputs.self.user) username;
in
{
  users.users.${username}.extraGroups = [ "networkmanager" ]; # wifi
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
    autoStart = lib.mkDefault false;
    gateway = "vpn-ac.urz.uni-heidelberg.de";
    user = "un330";
    protocol = "anyconnect";
    passwordFile = secrets.hdpw.path;
    extraOptions = {
      token-mode = "totp";
      token-secret = "@${secrets.hdotp.path}";
      # give up on a dead backend after one retry: a fresh session goes through
      # the load balancer, a reconnect clings to the same server
      reconnect-timeout = "30";
      script = "${pkgs.vpn-slice}/bin/vpn-slice --no-host-names --no-ns-hosts bwunicluster.scc.kit.edu 129.206.0.0/16 147.142.0.0/16";
    };
  };
  # every start spends a TOTP: never replay a code, back off, and stop well
  # before the token locks (`systemctl reset-failed` resumes)
  systemd.services.openconnect-uhd = {
    startLimitIntervalSec = 3600;
    startLimitBurst = 10;
    serviceConfig = {
      Restart = "always";
      RestartSec = 35;
      RestartSteps = 5;
      RestartMaxDelaySec = "10min";
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
        StreamLocalBindUnlink = true;
      };
    };
  };
}
