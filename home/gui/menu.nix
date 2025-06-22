{ lib, ... }:
{
  programs = {
    bemenu = {
      enable = true;
      settings = {
        line-height = 28;
        prompt = "open";
        list = 5;
        ignorecase = true;
      };
    };
  };
}
