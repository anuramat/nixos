{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    escapeShellArg
    getExe
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  busName = "org.freedesktop.secrets";
  cargo = lib.importTOML "${inputs.pass-secret-service}/Cargo.toml";
  package = pkgs.rustPlatform.buildRustPackage {
    pname = cargo.package.name;
    version = cargo.package.version;
    src = inputs.pass-secret-service;
    cargoLock.lockFile = "${inputs.pass-secret-service}/Cargo.lock";
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      wrapProgram $out/bin/pass-secret-service \
        --prefix PATH : ${lib.makeBinPath [ pkgs.gnupg ]}
    '';
    meta.mainProgram = "pass-secret-service";
  };

  cfg = config.services.pss;
  python = pkgs.python3.withPackages (ps: [ ps.dbus-next ]);
  migrate = pkgs.writeShellApplication {
    name = "pss-migrate";
    runtimeInputs = [
      python
      pkgs.gnupg
    ];
    text = ''
      ${optionalString (
        cfg.storePath != null
      ) "export PASSWORD_STORE_DIR=${escapeShellArg cfg.storePath}"}
      export GNUPGHOME=${escapeShellArg config.programs.gpg.homedir}
      exec python ${./pss-migrate.py} "$@"
    '';
  };
  command = "${getExe cfg.package}${
    optionalString (cfg.storePath != null) " --path ${cfg.storePath}"
  }";
in
{
  options.services.pss = {
    enable = mkEnableOption "Rust pass-secret-service";
    package = mkOption {
      type = types.package;
      default = package;
    };
    storePath = mkOption {
      type = types.nullOr types.str;
      default = config.programs.password-store.settings.PASSWORD_STORE_DIR or null;
      defaultText = "$HOME/.password-store";
    };
    migrationPackage = mkOption {
      type = types.package;
      default = migrate;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.pss" pkgs lib.platforms.linux)
      {
        assertion = !config.services.gnome-keyring.enable;
        message = ''
          Only one secrets service per user can be enabled at a time.
          Other services enabled:
          - gnome-keyring
        '';
      }
      {
        assertion = !config.services.pass-secret-service.enable;
        message = "services.pss replaces services.pass-secret-service; enable only one.";
      }
    ];

    systemd.user.services.pass-secret-service = {
      Unit = {
        AssertFileIsExecutable = getExe cfg.package;
        Description = "org.freedesktop.secrets agent for pass";
        Documentation = "https://github.com/grimsteel/pass-secret-service";
        PartOf = [ "default.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = busName;
        ExecStart = command;
        Environment = [ "GNUPGHOME=${config.programs.gpg.homedir}" ];
      };
      Install.WantedBy = [ "default.target" ];
    };

    home.packages = [ cfg.migrationPackage ];

    xdg.dataFile."dbus-1/services/${busName}.service".text = ''
      [D-BUS Service]
      Name=${busName}
      Exec=${command}
      SystemdService=pass-secret-service.service
    '';
  };
}
