{
  hostname,
  machines,
  lib,
}:
let
  inherit (builtins)
    filter
    attrValues
    concatStringsSep
    mapAttrs
    attrNames
    ;

  # TODO rename somehow idk
  machinesValid = mapAttrs (
    n: v:
    v
    // {
      hostKeys = v.hostKeys or "";
      sshKey = "";
    }
  ) machines;
  isBuilder = machinesValid.${hostname}.builder or false;
  others = lib.attrsets.filterAttrs (n: v: n != hostname) machinesValid;
  builders = lib.attrsets.filterAttrs (n: v: v.builder or false) others;
  builderHostnames = attrNames builders;
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
  ] ++ (others |> attrValues |> filter (x: x ? sshKey) |> map (x: x.sshKey));
  # TODO disentangle ssh keys, move to builder_config.nix or something idk
  substituters = map (x: "ssh-ng://${x}") builderHostnames;
  trusted-public-keys = map (x: x.cacheKey) (attrValues builders);
  builderUsername = "builder";
  hostKeys =
    others |> attrValues |> filter (x: x ? hostKeys) |> map (x: x.hostKeys) |> concatStringsSep "\n";
}
