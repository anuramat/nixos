{
  lib,
  inputs,
  osConfig ? null,
  ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];
  # TODO read the comment and verify; code seems to be fine
  # SLOP
  # Re-declare the option nixvim already defines, solely to extend its submodule's
  # specialArgs: submoduleWith declarations of the same option merge, concatenating
  # `modules` and combining `specialArgs` (it errors on a key set by both sides). This
  # injects `inputs` (and `osConfig` under NixOS) into every nixvim module, replacing a
  # hand-rolled `_module.args` inside the submodule.
  # https://nixos.org/manual/nixpkgs/stable/#module-system-lib-types-submoduleWith
  options.programs.nixvim = lib.mkOption {
    type = lib.types.submoduleWith {
      modules = [ ];
      specialArgs = {
        inherit inputs;
      }
      // (if osConfig == null then { } else { inherit osConfig; });
    };
  };
}
