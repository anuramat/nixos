# physical machines
{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.self.homeModules.todo ];

  home.packages = with pkgs; [
    smartmontools # storage
  ];

  programs.todo = {
    enable = true;
    file = "${config.home.homeDirectory}/notes/todo.txt";
  };
}
