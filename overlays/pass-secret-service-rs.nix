{ inputs, lib, ... }:
_final: prev:
let
  cargo = lib.importTOML "${inputs.pass-secret-service}/Cargo.toml";
in
{
  # unlike nixpkgs' pass-secret-service, the Rust one; see services.pss
  pass-secret-service-rs = prev.rustPlatform.buildRustPackage {
    pname = cargo.package.name;
    inherit (cargo.package) version;
    src = inputs.pass-secret-service;
    cargoLock.lockFile = "${inputs.pass-secret-service}/Cargo.lock";
    nativeBuildInputs = [ prev.makeWrapper ];
    postInstall = ''
      wrapProgram $out/bin/pass-secret-service \
        --prefix PATH : ${lib.makeBinPath [ prev.gnupg ]}
    '';
    meta.mainProgram = "pass-secret-service";
  };
}
