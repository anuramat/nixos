{
  config,
  lib,
  pkgs,
  ...
}:
# adapted from https://github.com/nephilus/nx-studio-wine
# install: nx-studio-install
let
  prefix = "${config.xdg.dataHome}/nx-studio/prefix";
  # 64-bit, unlike pkgs.wine; Full has GStreamer for video, and embeds Mono and Gecko (NX Studio seems
  # to draw some dialogs with MSHTML), so wineboot doesn't prompt to download them;
  # >= 11.17: earlier SymCrypt rsaenh mangles exponent-of-one RSA keys, breaking the Nikon ID sign-in
  wine = pkgs.wineWow64Packages.stagingFull;
  # Nikon's installer is an InstallShield Suite wrapper that can't run unattended, so click through its
  # language and Read Me screens on a virtual display, and keep the packages it then unpacks, to install
  # each silently with the arguments from the wrapper's setup.xml
  packages =
    let
      installer = pkgs.fetchurl {
        url = "https://download.nikonimglib.com/archive8/kJ1us006seib07wgA0S52dlxyQ23/S-NXSTDO-011001WF-ALLIN-ALL___.exe";
        hash = "sha256-7VT4kJfTJ3rIlmQI/x8dIAAco+IePtzH6xjXB9T84ls=";
      };
      unpack = pkgs.writeShellApplication {
        name = "unpack";
        runtimeInputs = [
          wine
          pkgs.xdotool
        ];
        text = ''
          dst=$1
          win() {
            for _ in $(seq 300); do
              w=$(xdotool search --onlyvisible --name "$1" | head -1) && [ -n "$w" ] && echo "$w" && return
              sleep 1
            done
            echo "timed out waiting for window: $1" >&2
            return 1
          }
          mkdir -p "$WINEPREFIX"
          # under the default win10, the wrapper hangs in its first InstallScript action
          winecfg -v win11
          wine ${installer} /silent &
          w=$(win '^Language Selection$')
          sleep 2
          xdotool mousemove --window "$w" 300 294 sleep 0.3 click 1 # the custom-drawn Install button
          w=$(win '^Read Me$')
          sleep 1
          xdotool windowfocus "$w" key Return
          # NX Studio's own setup asking for a language: everything is unpacked by now
          win 'InstallShield Wizard' >/dev/null
          cd "$WINEPREFIX"/drive_c/users/*/AppData/Local/Downloaded\ Installations
          mkdir -p "$dst/vcredist"
          cp '{237BF186-A2AF-48C2-BFC9-0AA2DA3829DD}/VC_redist.x64.exe' '{72AAD3AB-420C-41F0-9BE5-D854C4037DEF}/VC_redist.x86.exe' "$dst/vcredist"
          cp -r '{CCF5B9BF-F16D-4FAA-8B46-E932EA008361}' "$dst/nxstudio"
          cp -r '{327FA429-2B8C-4508-8538-037ECB4A9158}' "$dst/profiles"
          cp -r '{83D48551-3FF2-437E-B931-BF45011C6F87}' "$dst/opc"
          cp -r '{10D48481-31AC-42B0-91AC-25241A5E51E2}' "$dst/transfer2"
          wineserver -k
        '';
      };
    in
    pkgs.runCommand "nx-studio-1.10.1"
      {
        nativeBuildInputs = [ pkgs.xvfb-run ];
        outputHashMode = "recursive";
        outputHash = "sha256-HJ+nI5rpyPzC1vAqGarsgLIGM2SxbclFeV9qSoTPtJI=";
      }
      ''
        HOME=$TMPDIR WINEPREFIX=$TMPDIR/prefix WINEDEBUG=-all xvfb-run -s '-screen 0 1280x1024x24' ${lib.getExe unpack} "$out"
      '';
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
      runtimeInputs = [ wine ];
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
