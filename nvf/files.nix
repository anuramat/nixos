{ lib, ... }:
{
  vim = {
    filetree.neo-tree.enable = true;
    keymaps =
      let
        inherit (lib.nvim.binds) mkKeymap;
      in
      [
        (mkKeymap "n" "<leader>o" "<cmd>Oil<cr>" { })
        (mkKeymap "n" "<leader>O" "<cmd>Oil .<cr>" { })
      ];
    utility.oil-nvim = {
      enable = true;
      setupOpts = {
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
            type = "asc";
            name = "asc";
          };
        };
      };
    };
  };
}
