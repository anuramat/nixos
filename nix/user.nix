{
  hostname,
  machines,
  lib,
}:
let
  inherit (builtins)
    filter
    attrValues
    attrNames
    ;
  inherit (lib.attrsets) filterAttrs mapAttrs;

  others = filterAttrs (n: v: n != hostname) machines;
  builders = filterAttrs (n: v: v.builder or false) others;
in
# TODO split the file?
{
  inherit hostname builders;
  isBuilder = machines.${hostname}.builder or false;
  username = "anuramat";
  fullname = "Arsen Nuramatov";
  timezone = "Europe/Berlin";
  defaultLocale = "en_US.UTF-8";
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKl0YHcx+ju+3rsPerkAXoo2zI4FXRHaxzfq8mNHCiSD anuramat-iphone16"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBre248H/l0+aS5MJ+nr99m10g44y+UsaKTruszS6+D anuramat-ipad"
  ] ++ (others |> attrValues |> filter (x: x ? sshKey) |> map (x: x.sshKey));
  substituters = builders |> attrNames |> map (x: "ssh-ng://${x}");
  trusted-public-keys = builders |> attrValues |> map (x: x.cacheKey);
  builderUsername = "builder";
  knownHosts =
    others |> filterAttrs (n: v: v ? hostKeys) |> mapAttrs (n: v: { publicKey = v.hostKeys; });
}
