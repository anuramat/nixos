{ lib, ... }:
{
  vim = {
    languages.markdown.enable = true;
    lsp.otter-nvim = {
      enable = true;
      mappings.toggle = lib.mkForce null;
    };
  };
}
