{ lib, ... }:
{
  bemenu = {
    enable = true;
    settings = {
      line-height = 28;
      prompt = "open";
      list = 5;
      fn = lib.mkForce "Hack Nerd Font 16";
      ignorecase = true;
    };
  };
}
