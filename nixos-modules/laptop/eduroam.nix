# eduroam with the university account; the RADIUS server is pinned to its
# name and Telekom's root CA, so a rogue AP can't collect the password
{ config, lib, ... }:
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
        # stored in the profile: NM asks a secret agent only if it belongs to
        # the user who started the activation, so a root agent like
        # nm-file-secret-agent never answers when the user picks the network
        password = "$HDPW";
      };
    };
  };
  # substituted by envsubst in the script
  systemd.services.NetworkManager-ensure-profiles.script = lib.mkBefore ''
    export HDPW=$(< ${config.age.secrets.hdpw.path})
  '';
}
