{
  hostname,
  machines,
  lib,
}:
let
  # TODO rename somehow idk
  machinesValid = builtins.mapAttrs (n: v: v // { builder = v.builder or false; }) machines;
  isBuilder = machinesValid.${hostname}.builder;
  others = lib.attrsets.filterAttrs (n: v: n != hostname) machinesValid;
  builders = lib.attrsets.filterAttrs (n: v: v.builder or false) others;
  builderHostnames = builtins.attrNames builders;
in
{
  # WARN don't fuck this up
  inherit hostname isBuilder builderHostnames;
  username = "anuramat";
  fullname = "Arsen Nuramatov";
  timezone = "Europe/Berlin";
  defaultLocale = "en_US.UTF-8";
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKl0YHcx+ju+3rsPerkAXoo2zI4FXRHaxzfq8mNHCiSD anuramat-iphone16"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBre248H/l0+aS5MJ+nr99m10g44y+UsaKTruszS6+D anuramat-ipad"
  ] ++ map (x: x.sshKey) (builtins.attrValues others);
  # TODO disentangle ssh keys, move to builder_config.nix or something idk
  substituters = map (x: "http://${x}:5000") builderHostnames;
  trusted-public-keys = map (x: x.cacheKey) (builtins.attrValues builders);
  builderUsername = "builder";
}
