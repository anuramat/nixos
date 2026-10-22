# eduroam with the university account; the RADIUS server is pinned to its
# name and Telekom's root CA, so a rogue AP can't collect the password
{ config, ... }:
let
  id = "eduroam";
in
{
  networking.networkmanager.ensureProfiles = {
    profiles.${id} = {
      connection = {
        inherit id;
        type = "wifi";
        autoconnect-priority = 1;
      };
      wifi.ssid = "eduroam";
      wifi-security.key-mgmt = "wpa-eap";
      "802-1x" = {
        eap = "ttls";
        phase2-auth = "pap";
        identity = "un330@uni-heidelberg.de";
        anonymous-identity = "eduroamHDcat2024@uni-heidelberg.de";
        ca-cert = "${./t-telesec-globalroot-class2.pem}";
        altsubject-matches = "DNS:radius-node1.urz.uni-heidelberg.de";
        password-flags = 1; # agent-owned: served from the file below
      };
    };
    secrets.entries = [
      {
        matchId = id;
        matchSetting = "802-1x";
        key = "password";
        file = config.age.secrets.hdpw.path;
      }
    ];
  };
}
