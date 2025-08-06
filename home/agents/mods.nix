{
  config,
  pkgs,
  osConfig,
  ...
}:

let
  mods = config.lib.home.agenixPatchPkg pkgs.mods (
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
