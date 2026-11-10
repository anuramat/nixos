# SLOP
# Nikon's Image SDK, Windows-only, for native Linux clients; the protocol is in worker.cpp
# The target is the Nikon Z5II: other cameras only get what works for it at no extra effort
_: _final: prev:
let
  version = "1.47.0";
  sdk = prev.requireFile {
    name = "S-SDKNEF-001BF-ALLIN.zip";
    hash = "sha256-bXNObmDwwChtyEEHbFopI2+w/s6kxl+WcwfzEnko/d8=";
    message = "Download the zip from Nikon, then run: nix-store --add-fixed sha256 S-SDKNEF-001BF-ALLIN.zip";
  };
  runtime =
    prev.runCommand "nef-worker-runtime-${version}"
      {
        nativeBuildInputs = [
          prev.unzip
          prev.zig
        ];
      }
      ''
        unzip -q ${sdk} '*/win/Include/*' '*/win/Bin/x64/Release/*' '*/win/Profiles/*' '*/win/MiniSDK/WBLibrary/*'
        cd 'Image SDK/Library/win'
        mkdir $out
        cp -r Profiles $out
        cd Bin/x64/Release
        cp NkImgSDK.dll Elm.dll Elm.nlf RCSigProc.dll tbb.dll tbbmalloc.dll prm.bin $out
        cd ../../..
        export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig
        # NkMiniLib asks for MSVC's libraries by name; worker.cpp has what it needs from them
        for lib in uuid libcpmt LIBCMT OLDNAMES; do echo '!<arch>' >lib$lib.a; done
        zig c++ -target x86_64-windows-gnu -std=c++17 -O2 -s -static -D_WINDOWS -L . \
          -I Include -I MiniSDK/WBLibrary -I ${prev.nlohmann_json}/include \
          ${./worker.cpp} MiniSDK/WBLibrary/win/Release64/NkMiniLib.lib -o $out/nef-worker.exe
      '';
in
{
  nef-worker = prev.writeShellApplication {
    name = "nef-worker";
    runtimeInputs = [ prev.wine64 ]; # the SDK is 64-bit, unlike pkgs.wine
    runtimeEnv = {
      WINEDEBUG = "-all";
      WINEDLLOVERRIDES = "mscoree,mshtml="; # the SDK needs neither Mono nor Gecko
    };
    text = ''
      export WINEPREFIX="''${XDG_CACHE_HOME:-$HOME/.cache}/nef-worker/prefix"
      nikon="$WINEPREFIX/drive_c/Program Files/Common Files/Nikon"
      mkdir -p "$nikon"
      # the SDK only looks for its profiles here
      ln -sfn ${runtime}/Profiles "$nikon/Profiles"
      exec wine ${runtime}/nef-worker.exe "$@"
    '';
  };
}
