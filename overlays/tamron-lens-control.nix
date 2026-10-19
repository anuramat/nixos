{ inputs, lib, ... }:
_final: prev:
let
  # bind cp210x to Tamron lenses, which it doesn't claim by default
  rules =
    [
      "0002"
      "0005"
    ]
    |> map (pid: ''
      ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_interface", DRIVER=="", ATTRS{idVendor}=="2cd1", ATTRS{idProduct}=="${pid}", RUN+="${prev.runtimeShell} -c '${prev.kmod}/bin/modprobe cp210x && echo 2cd1 ${pid} > /sys/bus/usb-serial/drivers/cp210x/new_id'"
    '')
    |> lib.concatStrings
    |> prev.writeText "tamron-lens-control.rules";
in
{
  tamron-lens-control = prev.rustPlatform.buildRustPackage {
    pname = "tamron-lens-control";
    version = "0.1.1-dev";
    src = inputs.tamron-lens-control;
    cargoLock.lockFile = "${inputs.tamron-lens-control}/Cargo.lock";
    nativeBuildInputs = [ prev.pkg-config ];
    buildInputs = [ prev.udev ]; # serialport enumeration
    # for services.udev.packages
    postInstall = "install -Dm644 ${rules} $out/lib/udev/rules.d/99-tamron-lens-control.rules";
    meta.mainProgram = "tlc";
  };
}
