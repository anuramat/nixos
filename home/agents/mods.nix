{
  config,
  pkgs,
  osConfig,
  lib,
  ...
}:

let
  mods = config.lib.home.agenixPatch pkgs.mods (
    with osConfig.age.secrets;
    {
      inherit
        gemini
        openrouter
        anthropic
        oai
        ;
    }
  );
in
{

  home = {
    packages = [
      mods
    ];
  };
}
