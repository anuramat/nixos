# sources default to NIX_PATH, which NixOS points at the system flake's inputs
{
  pkgs ? import <nixpkgs> { },
  crane ? <crane>,
  modern-normalize ? <modern-normalize>,
  photoswipe ? <photoswipe>,
}:
let
  inherit (pkgs) lib runCommand;
  craneLib = import crane { inherit pkgs; };
  # embedded at compile time; copies, since rust-embed's debug builds
  # refuse symlinks that leave the folder
  vendor = runCommand "ctrlsn-vendor" { } ''
    install -Dm644 ${modern-normalize}/modern-normalize.css $out/css/modern-normalize.css
    install -Dm644 -t $out/js ${photoswipe}/dist/photoswipe{,-lightbox}.esm.min.js
    install -Dm644 -t $out/css ${photoswipe}/dist/photoswipe.css
  '';
  commonArgs = {
    src = craneLib.cleanCargoSource ./.;
    strictDeps = true;
  };
in
craneLib.buildPackage (
  commonArgs
  // {
    cargoArtifacts = craneLib.buildDepsOnly commonArgs;
    # static/ is embedded at compile time and read by the tests
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        (craneLib.fileset.commonCargoSources ./.)
        ./static
      ];
    };
    env.CTRLSN_VENDOR = vendor;
    passthru = { inherit vendor; };
    meta.mainProgram = "ctrlsn";
  }
)
