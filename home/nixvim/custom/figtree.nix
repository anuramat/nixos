{ pkgs, ... }:
{
  extraPlugins = [
    (
      let
        rev = "68ecf23c9c161983a7ef4bf53b0d4051873b7386";
      in
      pkgs.vimUtils.buildVimPlugin {
        pname = "figtree.nvim";
        version = "nightly";
        src = pkgs.fetchFromGitHub {
          inherit rev;
          owner = "anuramat";
          repo = "figtree.nvim";
          sha256 = "sha256-X5ZzbvztDG2S1gRl7zrhj1lcOi29dXjaZkCvvR6R/50=";
        };
      }
    )
  ];
  extraConfigLua = ''
    require('figtree').setup({
    })
  '';
}
