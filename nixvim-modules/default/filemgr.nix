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
      map = key: action: desc: {
        mode = "n";
        inherit key action;
        options = { inherit desc; };
      };
    in
    [
      (map "<leader>o" "<cmd>Oil<cr>" "Oil: parent directory of the file")
      (map "<leader>O" "<cmd>Oil .<cr>" "Oil: CWD")

      (map "<leader>tt" "<cmd>Neotree show last toggle<cr>" "Neotree: toggle")
      (map "<leader>tf" "<cmd>Neotree focus last<cr>" "Neotree: focus")
      (map "<leader>tr" "<cmd>Neotree show reveal<cr>" "Neotree: current file")
      (map "<leader>tg" "<cmd>Neotree show git_status<cr>" "Neotree: git status")
    ];
}
