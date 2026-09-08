{
  pkgs,
  config,
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
in
{
  imports = [
    ./gui.nix
    ./hosts.nix
    ./bash
    ./bin
    ./git
    ./keyring.nix
    ./lib.nix
    ./misc.nix
    ./packages.nix
    ./pss.nix
    ./readline.nix
    ./search.nix
    ./yazi.nix
  ];

  home.packages = [
    uc3
    uc3-askpass
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # NOTE: deprecated, removed in next release
    settings = {
      bgm5.HostName = "anuramat-bgm5";
      uc3 = {
        User = "hd_un330";
        HostName = "bwunicluster.scc.kit.edu";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/cm-%r@%h-%p";
        ControlPersist = "yes";
        ServerAliveInterval = 60;
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
