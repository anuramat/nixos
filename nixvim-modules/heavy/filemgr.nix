{ config, ... }:
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
          sort = [
            [
              "type"
              "asc"
            ]
            [
              "name"
              "asc"
            ]
          ];
        };
      };
    };
  };
  keymaps =
    let
      nmap = config.lib.cmd "n";
    in
    [
      (nmap "<leader>o" "Oil" "Oil: parent directory of the file")
      (nmap "<leader>O" "Oil ." "Oil: CWD")

      (nmap "<leader>tt" "Neotree show last toggle" "Neotree: toggle")
      (nmap "<leader>tf" "Neotree focus last" "Neotree: focus")
      (nmap "<leader>tr" "Neotree show reveal" "Neotree: current file")
      (nmap "<leader>tg" "Neotree show git_status" "Neotree: git status")
    ];
}
