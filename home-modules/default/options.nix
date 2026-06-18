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
