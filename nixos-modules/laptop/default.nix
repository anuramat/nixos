{
  imports = [
    ./battery-graph.nix
    ./eduroam.nix
    ./power.nix
    ./keyboard.nix
  ];
  networking.openconnect.interfaces.uhd.autoStart = true;
}
