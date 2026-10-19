# physical machines
{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    libusb1 # user-mode USB access lib
    qrcp # share files over qr
    smartmontools # storage
  ];

  programs.todo = {
    enable = true;
    file = "${config.home.homeDirectory}/notes/todo.txt";
  };

  xdg.configFile."qrcp/config.yml".text = lib.generators.toYAML { } {
    interface = "any";
    keepalive = true;
    port = 9000;
  };
}
