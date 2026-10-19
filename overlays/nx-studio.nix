{ inputs, ... }:
# adapted from https://github.com/nephilus/nx-studio-wine
# install: nx-studio-install
_final: prev:
let
  version = "1.11.0";
  # 64-bit, unlike pkgs.wine; Full has GStreamer for video, and embeds Mono and Gecko (NX Studio seems
  # to draw some dialogs with MSHTML), so wineboot doesn't prompt to download them;
  # >= 11.17: earlier SymCrypt rsaenh mangles exponent-of-one RSA keys, breaking the Nikon ID sign-in;
  # unstable: 26.05 embeds a Mono older than its wine wants
  wine =
    (import inputs.nixpkgs-unstable {
      inherit (prev) config;
      inherit (prev.stdenv.hostPlatform) system;
    }).wineWow64Packages.stagingFull;
  # Nikon's installer is an InstallShield Suite wrapper that can't run unattended, so unpack the packages
  # it bundles, to install each silently with the arguments from the wrapper's setup.xml
  packages =
    let
      installer = prev.fetchurl {
        url = "https://download.nikonimglib.com/archive8/Aibnt00VXE9I07ccQd268b5a0w12/S-NXSTDO-011100WF-ALLIN-ALL___.exe";
        hash = "sha256-PlC0zTzgy9Rn8uWdhk3PajTBpM4o3TgTSNS6KbVdAHU=";
      };
      # decodes the ISSetupStream appended to the wrapper, as https://github.com/lifenjoiner/ISx does
      unpack = prev.writers.writePython3 "unpack" { } ''
        import itertools
        import os
        import struct
        import sys
        import zlib

        data = open(sys.argv[1], "rb").read()
        # the last match: the engine's code has the signature too
        pos = data.rindex(b"ISSetupStream\0")
        (count,) = struct.unpack_from("<H", data, pos + 14)
        pos += 46
        swap = bytes((b << 4 | b >> 4) & 0xFF for b in range(256))
        for _ in range(count):
            # 48 bytes: name length, flags, size, zlib flag, timestamps; UTF-16 name
            name_len, size, deflated = struct.unpack_from("<I6xI8xH", data, pos)
            pos += 48
            name = data[pos:pos + name_len].decode("utf-16-le")
            pos += name_len
            # nibble-swapped, then XORed with the salted name, restarting every KiB
            salt = itertools.cycle(b"\x13\x35\x86\x07")
            key = [c ^ s ^ 0xFF for c, s in zip(name.encode(), salt)]
            mask = bytes(itertools.islice(itertools.cycle(key), 1024))
            mask *= size // 1024 + 1
            blob = data[pos:pos + size].translate(swap)
            pos += size
            blob = int.from_bytes(blob) ^ int.from_bytes(mask[:size])
            blob = blob.to_bytes(size)
            path = name.replace("\\", "/")
            os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
            open(path, "wb").write(zlib.decompress(blob) if deflated else blob)
      '';
    in
    prev.runCommand "nx-studio-packages-${version}" { } ''
      ${unpack} ${installer}
      mkdir -p $out/vcredist
      mv '{237BF186-A2AF-48C2-BFC9-0AA2DA3829DD}/VC_redist.x64.exe' '{72AAD3AB-420C-41F0-9BE5-D854C4037DEF}/VC_redist.x86.exe' $out/vcredist
      mv '{CCF5B9BF-F16D-4FAA-8B46-E932EA008361}' $out/nxstudio
      mv '{327FA429-2B8C-4508-8538-037ECB4A9158}' $out/profiles
      mv '{83D48551-3FF2-437E-B931-BF45011C6F87}' $out/opc
      mv '{10D48481-31AC-42B0-91AC-25241A5E51E2}' $out/transfer2
    '';
  # runtime for the Nikon ID login window; to update, follow
  # https://go.microsoft.com/fwlink/?linkid=2124701 (x64 standalone installer)
  webview2 = prev.fetchurl {
    url = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/7c7c0e6f-8cb5-406a-8e51-df0c62011e55/MicrosoftEdgeWebView2RuntimeInstallerX64.exe";
    hash = "sha256-KmrddsN7+ocuuMKyLUWzIWuOKh8ZPgd0AGNA/2KsX6A=";
  };
  script =
    name: text:
    prev.writeShellApplication {
      inherit name;
      runtimeInputs = [ wine ];
      # the installer's Start Menu shortcuts would become menu entries calling the 32-bit wine from PATH
      runtimeEnv.WINEDLLOVERRIDES = "winemenubuilder.exe=d";
      text = ''
        export WINEPREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/nx-studio/prefix"
      ''
      + text;
    };
in
{
  nx-studio = prev.symlinkJoin {
    pname = "nx-studio";
    inherit version;
    paths = [
      (script "nx-studio" ''
        # wine ignores the scale that xwayland-satellite publishes in XSETTINGS
        dpi=$(${prev.xsettingsd}/bin/dump_xsettings | awk '$1 == "Xft/DPI" { print int($2 / 1024) }')
        wine reg add 'HKCU\Control Panel\Desktop' /v LogPixels /t REG_DWORD /d "$dpi" /f >/dev/null
        exec wine "$WINEPREFIX/drive_c/Program Files/Nikon/NXStudio/NXStudio.exe" "$@"
      '')
      (script "nx-studio-wine" ''exec "$@"'') # e.g. `nx-studio-wine winecfg`
      (script "nx-studio-install" ''
        # start over instead of relying on the setups' upgrade paths
        if [[ -e $WINEPREFIX ]]; then
          read -rp "Replace $WINEPREFIX, resetting the sign-in and settings? [y/N] " answer
          [[ $answer == y ]] || exit 1
          rm -rf "$WINEPREFIX"
        fi
        # wine doesn't create missing parent directories
        mkdir -p "$WINEPREFIX"
        wineboot -i
        # the InstallScript setups write their logs next to themselves
        cd "$(mktemp -d)"
        cp -r --no-preserve=mode ${packages}/. .
        # setup.exe launchers can return before the install finishes
        setup() { wine "$@"; wineserver -w; }
        setup vcredist/VC_redist.x64.exe /q /norestart
        setup vcredist/VC_redist.x86.exe /q /norestart
        # REGION: one of JPN, NSA, EUR, CND, INT
        setup nxstudio/setup.exe /l1033 /s /v/qn /vINSTTYPE=DL /vREGION=EUR /vONLINE=online /vENVCHECK=true
        setup profiles/setup.exe /l1033 /s WOW64
        setup opc/ApLaunch.exe /l1033 /s /vREGION=EUR
        setup transfer2/setup.exe /l1033 /s /v/qn /vREGION=EUR '/vDELIVERYROOT="NXST_DL"'
        wine ${webview2} /silent /install
      '')
      (prev.makeDesktopItem {
        name = "nx-studio";
        desktopName = "NX Studio";
        comment = "Browse and edit Nikon photos";
        exec = "nx-studio %F";
        icon = "applications-graphics";
        categories = [
          "Graphics"
          "Photography"
        ];
        mimeTypes = [
          "image/jpeg"
          "image/tiff"
          "image/x-nikon-nef"
        ];
      })
    ];
    meta.mainProgram = "nx-studio";
  };
}
