{
  config,
  osConfig ? null,
  lib,
  ...
}:
{
  imports = [
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
    ./typst.nix
    ./yazi.nix
  ];

  programs.ssh = {
    enable = true;
    extraConfig =
      let
        prefix = config.home.username + "-";
        mkAliasEntry =
          hostname: # ssh_config
          ''
            Host ${lib.strings.removePrefix prefix hostname}
              HostName ${hostname}
          '';
        machines =
          if osConfig == null then
            [ ]
          else
            (
              (builtins.attrNames osConfig.lib.hosts.hosts)
              |> lib.filter (x: lib.strings.hasPrefix prefix x)
              |> map mkAliasEntry
            );
        bw = ''
          Host bw
            User hd_un330
            HostName bwunicluster.scc.kit.edu
        '';
        entries = machines ++ [ bw ];
      in
      entries |> lib.strings.intersperse "\n" |> lib.concatStrings;
  };

  xdg.enable = true; # set xdg basedir vars in .profile

  programs.home-manager.enable = true; # TODO huh? what does this do

  home.preferXdgDirectories = true;

  xdg.configFile."nixpkgs/config.nix".text = # nix
    ''
      { allowUnfree = true; }
    '';
}
