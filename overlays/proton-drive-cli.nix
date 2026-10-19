{ lib, ... }:
_final: prev: {
  proton-drive-cli =
    let
      version = "0.8.0";
      srcs = {
        x86_64-linux = {
          url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
          hash = "sha512-z2HCaIxF4QVdit1iIdlHGlpbZL87zbhkYPXLGEFFlsxN8822YnyQl8lL7DKjyZFa2jIR7yrlvjPEbrvJlsyqKA==";
        };
        aarch64-linux = {
          url = "https://proton.me/download/drive/cli/${version}/linux-arm64/proton-drive";
          hash = "sha512-J6GuwdIJX9ShqB4dR80fn9SQG9V5/+UDQtFeLlIHjW6LLd3PWKSjhkONx1YgF3eL4mwbpiOZ+QGugsdDDiFAow==";
        };
        aarch64-darwin = {
          url = "https://proton.me/download/drive/cli/${version}/darwin-arm64/proton-drive";
          hash = "sha512-FIOi+mr+ekmr3DT2ZCC4fgpdSNI29vSnnq5/fXbcOmvuvtzeXiKc5f3vQkUK2kG7zAIWGmSvtHO8qk/ak4xzKQ==";
        };
        x86_64-darwin = {
          url = "https://proton.me/download/drive/cli/${version}/darwin-x64/proton-drive";
          hash = "sha512-T+2Tmr+6tKepbiqvFk1nLOPixswHF+ZbGMMcql9Szmbjq4Q+wvPEUaMmizgpHNlkYyqKv2ycjsN/VCiXMQbJ3Q==";
        };
      };
      isLinux = prev.stdenv.hostPlatform.isLinux;
    in
    prev.stdenv.mkDerivation {
      pname = "proton-drive-cli";
      inherit version;
      src = prev.fetchurl srcs.${prev.stdenv.hostPlatform.system};
      dontUnpack = true;
      dontStrip = true;
      # no patchelf: it corrupts the appended bun bundle; interpreter comes from nix-ld
      dontPatchELF = true;
      nativeBuildInputs = [ prev.makeWrapper ];
      installPhase =
        "install -Dm755 $src $out/bin/proton-drive"
        # bun dlopens libsecret; preload pulls it and its glib deps in first
        + lib.optionalString isLinux ''

          wrapProgram $out/bin/proton-drive \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ prev.libsecret ]} \
            --prefix LD_PRELOAD : ${prev.libsecret}/lib/libsecret-1.so.0
        '';
      meta.mainProgram = "proton-drive";
    };
}
