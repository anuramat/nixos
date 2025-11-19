{ pkgs, ... }:
{
  programs.gh = {
    enable = true;
    settings = {
      aliases = {
        login = "auth login --skip-ssh-key --hostname github.com --git-protocol ssh --web";
        push = "repo create --disable-issues --disable-wiki --public --source=.";
      };
      extensions = with pkgs; [
        gh-f
        gh-copilot
      ];
      git_protocol = "ssh";
      prompt = true;
    };
  };
}
