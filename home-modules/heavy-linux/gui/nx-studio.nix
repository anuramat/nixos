{ config, pkgs, ... }:
# adapted from https://github.com/nephilus/nx-studio-wine
# install: nx-studio-install
let
  prefix = "${config.xdg.dataHome}/nx-studio/prefix";
  # Nikon's S-NXSTDO-*.exe is an InstallShield Suite wrapper whose welcome dialog can't run unattended,
  # so these are the packages it unpacks, each installed silently with the arguments from its setup.xml
  packages = pkgs.requireFile {
    name = "nx-studio-1.10.1";
    hashMode = "recursive";
    hash = "sha256-7YwoG5yFKsQ8twPvAsVipUguHoUH+av/YoM3/SO4MAc=";
    message = ''
      Run Nikon's NX Studio installer in a scratch wine prefix, and once the NX Studio setup
      starts, copy these from drive_c/users/$USER/AppData/Local/Downloaded Installations/{GUID}/:
        vcredist/: VC_redist.x64.exe, VC_redist.x86.exe
        nxstudio/: NX Studio.msi, 1033.MST
        profiles/, opc/, transfer2/: the colour profile, Picture Control (ApLaunch.exe)
          and Nikon Transfer 2 packages, whole
      then: nix-store --add-fixed --recursive sha256 nx-studio-1.10.1
    '';
  };
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
      # the InstallScript setups write their logs next to themselves
      cd "$(mktemp -d)"
      cp -r --no-preserve=mode ${packages}/. .
      # setup.exe launchers can return before the install finishes
      setup() { wine "$@"; wineserver -w; }
      setup vcredist/VC_redist.x64.exe /q /norestart
      setup vcredist/VC_redist.x86.exe /q /norestart
      # REGION: one of JPN, NSA, EUR, CND, INT
      (cd nxstudio && setup msiexec /i 'NX Studio.msi' TRANSFORMS=1033.MST /qn INSTTYPE=DL REGION=EUR ONLINE=online ENVCHECK=true)
      setup profiles/setup.exe /l1033 /s WOW64
      setup opc/ApLaunch.exe /l1033 /s /vREGION=EUR
      setup transfer2/setup.exe /l1033 /s /v/qn /vREGION=EUR '/vDELIVERYROOT="NXST_DL"'
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
