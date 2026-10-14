{ config, pkgs, ... }:
# adapted from https://github.com/nephilus/nx-studio-wine
# install: nx-studio-install S-NXSTDO-*.exe (from Nikon's download center)
let
  prefix = "${config.xdg.dataHome}/nx-studio/prefix";
  # runtime for the Nikon ID login window; to update, follow
  # https://go.microsoft.com/fwlink/?linkid=2124701 (x64 standalone installer)
  webview2 = pkgs.fetchurl {
    url = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/7c7c0e6f-8cb5-406a-8e51-df0c62011e55/MicrosoftEdgeWebView2RuntimeInstallerX64.exe";
    hash = "sha256-KmrddsN7+ocuuMKyLUWzIWuOKh8ZPgd0AGNA/2KsX6A=";
  };
  script =
    name: text:
    pkgs.writeShellApplication {
      inherit name text;
      # 64-bit, unlike pkgs.wine; Full has GStreamer for video, and embeds Mono and Gecko (NX Studio seems
      # to draw some dialogs with MSHTML), so wineboot doesn't prompt to download them;
      # >= 11.17: earlier SymCrypt rsaenh mangles exponent-of-one RSA keys, breaking the Nikon ID sign-in
      runtimeInputs = [ pkgs.wineWow64Packages.stagingFull ];
      runtimeEnv = {
        WINEPREFIX = prefix;
        # the installer's Start Menu shortcuts would become menu entries calling the 32-bit wine from PATH
        WINEDLLOVERRIDES = "winemenubuilder.exe=d";
      };
    };
in
{
  home.packages = [
    (script "nx-studio" ''exec wine "${prefix}/drive_c/Program Files/Nikon/NXStudio/NXStudio.exe" "$@"'')
    (script "nx-studio-wine" ''exec "$@"'') # e.g. `nx-studio-wine winecfg` to set the DPI
    (script "nx-studio-install" ''
      # wine doesn't create missing parent directories
      mkdir -p "$WINEPREFIX"
      # from upstream, untested: wine defaults to win10, which NX Studio supports
      winecfg -v win11
      wine "$1"
      # keep the prefix on win11, but WebView2 needs win7;
      # from upstream, untested, but the usual fix for WebView2 under wine
      wine reg add 'HKCU\Software\Wine\AppDefaults\msedgewebview2.exe' /v Version /t REG_SZ /d win7 /f
      wine ${webview2} /silent /install
    '')
  ];

  xdg.desktopEntries.nx-studio = {
    name = "NX Studio";
    comment = "Browse and edit Nikon photos";
    exec = "nx-studio %F";
    icon = "applications-graphics";
    categories = [
      "Graphics"
      "Photography"
    ];
    mimeType = [
      "image/jpeg"
      "image/tiff"
      "image/x-nikon-nef"
    ];
  };

  programs.niri.settings.window-rules = [
    {
      matches = [
        {
          app-id = "^nxstudio\\.exe$";
          title = "^NX Studio";
        }
      ];
      open-maximized = true;
    }
  ];
}
