{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.age) secrets;
  inherit (inputs.self.consts.user) username;
  vpn = config.networking.openconnect.interfaces.uhd;
  ip = lib.getExe' pkgs.iproute2 "ip";
in
{
  users.users.${username}.extraGroups = [ "networkmanager" ]; # wifi
  networking = {
    firewall.interfaces.tailscale0.allowedTCPPorts = [ 12345 ]; # for adhoc stuff
    # keep tailnet peers off the VPN: between two clients, packets have to fit
    # both tunnels, but each client only knows its own MTU, so full-size
    # WireGuard packets vanish
    firewall.extraCommands =
      let
        rule = "OUTPUT -o uhd -p udp --sport ${toString config.services.tailscale.port} -j DROP";
      in
      ''
        ip46tables -D ${rule} 2>/dev/null || true
        ip46tables -A ${rule}
      '';
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
      # vpn-slice ignores attempt-reconnect: after a link change the route to
      # the gateway is gone, so the reconnect would go into the tunnel itself
      script = "${pkgs.writeShellScript "vpn-slice-uhd" ''
        if [ "$reason" = attempt-reconnect ]; then
          # no uplink yet: nothing to route around
          read -r _ _ gw _ dev _ < <(${ip} route show default) || exit 0
          exec ${ip} route replace "$VPNGATEWAY" via "$gw" dev "$dev"
        fi
        exec ${lib.getExe pkgs.vpn-slice} --no-host-names --no-ns-hosts bwunicluster.scc.kit.edu 129.206.0.0/16 147.142.0.0/16
      ''}";
    };
  };
  # every start spends a TOTP: never replay a code, back off, and stop well
  # before the token locks (`systemctl reset-failed` resumes)
  systemd.services.openconnect-uhd = {
    # with autoStart, the campus hook below starts it, once the uplink is up
    wantedBy = lib.mkForce [ ];
    startLimitIntervalSec = 3600;
    startLimitBurst = 10;
    serviceConfig = {
      Restart = "always";
      RestartSec = 35;
      RestartSteps = 5;
      RestartMaxDelaySec = "10min";
    };
  };
  # on campus the university ranges are reachable directly; elsewhere, reconnect
  # right away instead of waiting for dead peer detection; --no-block: the unit
  # is ordered after network-online.target, which waits for this very hook
  networking.networkmanager.dispatcherScripts = lib.mkIf vpn.autoStart [
    {
      source = pkgs.writeShellScript "uhd-campus" ''
        [ "$2" = up ] || exit 0
        read -r _ _ gw _ < <(${ip} route show default dev "$1") || exit 0
        systemctl=${lib.getExe' config.systemd.package "systemctl"}
        case $gw in
        129.206.* | 147.142.*) $systemctl stop openconnect-uhd ;;
        *) $systemctl kill -s USR2 --kill-whom=main openconnect-uhd || $systemctl start --no-block openconnect-uhd ;;
        esac
      '';
    }
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
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        PrintLastLog = false;
        # no passwords to guess, and a flaky link would lock out the whole
        # tailnet address of a host
        PerSourcePenalties = "no";
      };
    };
  };
}
