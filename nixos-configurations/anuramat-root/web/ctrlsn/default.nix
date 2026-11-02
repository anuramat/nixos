# sources default to NIX_PATH, which NixOS points at the system flake's inputs
{
  pkgs ? import <nixpkgs> { },
  crane ? <crane>,
  fslightbox ? <fslightbox>,
  modern-normalize ? <modern-normalize>,
}:
let
  inherit (pkgs) lib runCommand;
  craneLib = import crane { inherit pkgs; };
  # embedded at compile time; copies, since rust-embed's debug builds
  # refuse symlinks that leave the folder
  vendor = runCommand "ctrlsn-vendor" { } ''
    install -Dm644 ${fslightbox}/index.js $out/js/fslightbox.js
    install -Dm644 ${modern-normalize}/modern-normalize.css $out/css/modern-normalize.css
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
