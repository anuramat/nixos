{
  pkgs,
  lib,
  config,
  ...
}@args:
let
  inherit (pkgs) writeShellApplication writeScriptBin;
  inherit (builtins) readFile readDir;

  excludeShellChecks = map (v: "SC" + toString v) config.lib.excludeShellChecks.numbers;

  packages =
    with lib;
    readDir ./.
    |> attrNames
    |> map (
      filename:
      let
        text = readFile ./${filename};
        name = removeSuffix ("." + ext) filename;
        ext = filename |> splitString "." |> last;
      in
      if ext == "sh" then
        writeShellApplication {
          inherit name text excludeShellChecks;
        }
      else
        writeScriptBin name text
    );

  nix-cache-keygen =
    let
      # TODO read builders, move and read public
      private = args.osConfig.nix.settings.secret-key-files;
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
  home.packages = packages ++ (if args ? osConfig then [ nix-cache-keygen ] else [ ]);
}
