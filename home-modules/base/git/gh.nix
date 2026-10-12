{ pkgs, ... }:
{
  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-f ];
    settings = {
      aliases = {
        login = "auth login --skip-ssh-key --hostname github.com --git-protocol ssh --web";
        push = "repo create --disable-issues --disable-wiki --public --source=.";
      };
      git_protocol = "ssh";
    };
  };
}
