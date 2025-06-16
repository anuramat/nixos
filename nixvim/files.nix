{ lib, ... }:
{
  plugins = {
    neo-tree.enable = true;
    
    oil = {
      enable = true;
      settings = {
        default_file_explorer = true;
        columns = [
          "icon"
          "permissions"
          "size"
          "mtime"
        ];
        delete_to_trash = true;
        skip_confirm_for_simple_edits = true;
        constrain_cursor = "editable";
        experimental_watch_for_changes = true;
        view_options = {
          show_hidden = true;
          natural_order = true;
          sort = {
            "type" = "asc";
            "name" = "asc";
          };
        };
      };
    };
  };
  
  keymaps = [
    { mode = "n"; key = "<leader>o"; action = "<cmd>Oil<cr>"; }
    { mode = "n"; key = "<leader>O"; action = "<cmd>Oil .<cr>"; }
  ];
}