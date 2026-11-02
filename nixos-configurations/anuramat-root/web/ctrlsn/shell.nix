{
  pkgs ? import <nixpkgs> { },
}:
let
  ctrlsn = import ./. { inherit pkgs; };
in
pkgs.mkShell {
  CTRLSN_VENDOR = ctrlsn.vendor;
  inputsFrom = [ ctrlsn ];
  packages = with pkgs; [
    cargo-insta
    clippy
    rust-analyzer
  ];
}
