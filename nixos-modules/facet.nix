# facet (overlays/facet), for the hosts with a GPU it can use
{ inputs, pkgs, ... }:
{
  # harmonia has port 5000; the viewer's default dev mode watches its read-only source
  home-manager.users.${inputs.self.consts.user.username}.home.packages = [
    (pkgs.symlinkJoin {
      inherit (pkgs.facet) name meta;
      paths = [ pkgs.facet ];
      nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
      postBuild = ''
        wrapProgram $out/bin/facet --set-default PORT 5001
        wrapProgram $out/bin/facet-viewer --set-default PORT 5001 \
          --add-flags "--production --host 127.0.0.1"
      '';
    })
  ];
}
