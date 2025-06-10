{ lib, ... }:
let
  t480 = {
    criteria = "LG Display 0x0521 Unknown";
    position = "0,0";
  };
  ll7 = {
    criteria = "California Institute of Technology 0x1626 0x00006002";
    position = "0,0";
    scale = 1.5;
  };
  ext = {
    criteria = "Dell Inc. DELL S2722QC 192SH24";
    scale = 1.5;
    adaptiveSync = false;
  };

  rawProfiles = {
    ll7 = [
      ll7
    ];
    ll7-home = [
      (ll7 // { scale = 2.0; })
      (ext // { position = "1600,0"; })
    ];
    t480 = [
      t480
    ];
    t480-home = [
      t480
      (ext // { position = "0,-2000"; })
    ];
  };
  profiles = lib.mapAttrs (n: v: {
    outputs = v;
    name = n;
  }) rawProfiles;
in
{
  services.kanshi = {
    enable = true;
    settings = lib.mapAttrsToList (n: v: {
      profile = {
        name = n;
        outputs = v.outputs;
      };
    }) profiles;
  };
}
