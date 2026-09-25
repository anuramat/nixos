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
  sshHosts = lib.mapAttrs' (
    name: h:
    if h ? alias then lib.nameValuePair h.alias { HostName = name; } else lib.nameValuePair name { }
  ) inputs.self.hosts;
in
{
  imports = [
    ./gui.nix
    ./hosts.nix
    ./bash
    ./bin
    ./editor.nix
    ./git
    ./keyring.nix
    ./lib.nix
    ./misc.nix
    ./packages.nix
    ./pss.nix
    ./readline.nix
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
    settings = sshHosts // {
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

  programs.home-manager.enable = true; # TODO huh? what does this do

  home.preferXdgDirectories = true;

  xdg.configFile."nixpkgs/config.nix".text = # nix
    ''
      { allowUnfree = true; }
    '';
}
