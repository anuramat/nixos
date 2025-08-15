{ pkgs, lib, ... }:
{
  files =
    let
      basename = builtins.baseNameOf;
    in
    [
      rec {
        path_ = "flake.nix";
        drv =
          let
            template = lib.generators.toPretty { } {
              outputs = x: x;
              inputs = import ../inputs.nix;
            };
            text =
              builtins.replaceStrings [ "<function>" ] [ "args: import ./outputs.nix args" ] template + "\n";
          in
          pkgs.writeText (basename path_) text;
      }
    ];

}
