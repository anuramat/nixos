{ lib, ... }:
{
  vim = {
    notes.todo-comments = {
      enable = true;
      setupOpts = {
        signs = false;
        mappings = {
          quickFix = lib.mkForce null;
        };
        highlight = {
          keyword = "bg"; # only highlight the word itself
          pattern = ''<(KEYWORDS)>''; # vim regex
          multiline = false;
        };
        search = {
          pattern = ''\b(KEYWORDS)\b''; # ripgrep
        };
      };
    };
    assistant = {
      avante-nvim.enable = true;
      copilot.enable = true;
    };
  };
}
