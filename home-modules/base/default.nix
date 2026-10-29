{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
let
  uc3-askpass = pkgs.writeShellApplication {
    name = "uc3-askpass";
    runtimeInputs = [ pkgs.oath-toolkit ];
    text = ''
      case "$1" in
      	*OTP*) oathtool --totp -b @${config.lib.secrets.uc3-totp.path} ;;
      	*[Pp]assword*) cat ${config.lib.secrets.uc3-pw.path} ;;
      	*) exit ;;
      esac
    '';
  };
  uc3 = pkgs.writeShellApplication {
    name = "uc3";
    text = "SSH_ASKPASS=${lib.getExe uc3-askpass} SSH_ASKPASS_REQUIRE=force ssh uc3";
  };
  # NOTE hosts without an alias are explicitly listed for `wishlist`
  sshHosts =
    inputs.self.hosts
    |> lib.mapAttrs' (
      name: h:
      if h.alias != null then
        lib.nameValuePair h.alias { HostName = name; }
      else
        lib.nameValuePair name { }
    );
  # for background polling (e.g. the fleet monitor): one shared connection per
  # host, kept off interactive ssh so that bulk transfers never share it
  bgHosts =
    inputs.self.hosts
    |> lib.mapAttrs' (
      name: _:
      lib.nameValuePair "_bg-${name}" {
        HostName = name;
        BatchMode = "yes";
        ConnectTimeout = 5;
        ControlMaster = "auto";
        ControlPath = "\${XDG_RUNTIME_DIR}/ssh-bg-%C";
        ControlPersist = "10m";
        # drops a master left dead by a suspend or a network change
        ServerAliveInterval = 15;
        ServerAliveCountMax = 2;
      }
    );
in
{
  imports = [
    ./gui.nix
    ./bash
    ./editor.nix
    ./git
    ./keyring.nix
    ./lib.nix
    ./misc.nix
    ./packages.nix
    ./readline.nix
    ./tgfy.nix
    ./search.nix
    ./yazi.nix
    ./zellij.nix
  ];

  home.packages = [
    uc3
    uc3-askpass
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # NOTE: deprecated, removed in next release
    settings =
      sshHosts
      // bgHosts
      // {
        uc3 = {
          User = "hd_un330";
          HostName = "bwunicluster.scc.kit.edu";
          ControlMaster = "auto";
          ControlPath = "~/.ssh/cm-%r@%h-%p";
          ControlPersist = "yes";
          ServerAliveInterval = 60;
          # the askpass mints the same TOTP for a whole window: a second prompt
          # can only replay it, which the cluster counts as a failed attempt
          NumberOfPasswordPrompts = 1;
          WarnWeakCrypto = "no";
        };
      };
  };

  xdg.enable = true; # set xdg basedir vars in .profile

  home.preferXdgDirectories = true;

  xdg.configFile."nixpkgs/config.nix".text = # nix
    ''
      { allowUnfree = true; }
    '';
}
