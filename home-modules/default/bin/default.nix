{
  pkgs,
  lib,
  config,
  osConfig ? null,
  ...
}:
let
  inherit (pkgs) writeShellApplication;
  inherit (builtins) readFile readDir;

  excludeShellChecks = map (v: "SC" + toString v) config.lib.excludeShellChecks.numbers;

  packages =
    with lib;
    readDir ./.
    |> filterAttrs (name: type: hasSuffix ".sh" name && type == "regular")
    |> attrNames
    |> map (
      name:
      writeShellApplication {
        name = removeSuffix ".sh" name;
        text = readFile ./${name};
        inherit excludeShellChecks;
      }
    );

  nix-cache-keygen =
    let
      # TODO read builders, move and read public
      private = osConfig.nix.settings.secret-key-files;
      public = "/etc/nix/cache.pem.pub";
      builderName = "builder";
      builderGroup = "builder";
    in
    writeShellApplication {
      name = "nix-cache-keygen";
      inherit excludeShellChecks;
      text = ''
        if [ ! -e '${private}' ] && [ ! -e '${public}' ]; then
          sudo nix-store --generate-binary-cache-key "$(hostname)" '${private}' '${public}'
        fi
        sudo chown '${builderName}:${builderGroup}' '${private}' '${public}'
        [ ! -e "$HOME/.ssh" ] && yes "" | ssh-keygen -N ""
      '';
    };

  # TODO root ssh config from nix.nix?
in
{
  home.packages = packages ++ (if osConfig != null then [ nix-cache-keygen ] else [ ]);
}
