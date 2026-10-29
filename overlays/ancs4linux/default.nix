{ inputs, lib, ... }:
_final: prev:
let
  inherit (lib.importTOML "${inputs.ancs4linux}/pyproject.toml") project;
in
{
  # iOS notifications over BLE (ANCS); for services.dbus.packages and systemd.packages
  ancs4linux = prev.python3Packages.buildPythonApplication {
    pname = project.name;
    inherit (project) version;
    pyproject = true;
    src = inputs.ancs4linux;
    patches = [
      ./device-observer.patch
      ./desktop-clients.patch
      ./notification-details.patch
    ];
    build-system = [ prev.python3Packages.hatchling ];
    dependencies = with prev.python3Packages; [
      dasbus
      pygobject3
      typer
    ];
    nativeBuildInputs = [
      prev.gobject-introspection
      prev.wrapGAppsNoGuiHook
    ];
    postInstall = ''
      pushd autorun
      for f in *.xml; do install -Dm644 $f $out/share/dbus-1/system.d/''${f%.xml}.conf; done
      substituteInPlace *.service --replace-fail /usr/local/bin $out/bin
      install -Dm644 -t $out/lib/systemd/system ancs4linux-{advertising,observer}.service
      install -Dm644 -t $out/lib/systemd/user ancs4linux-desktop-integration.service
      popd
    '';
    meta.mainProgram = "ancs4linux-ctl";
  };
}
