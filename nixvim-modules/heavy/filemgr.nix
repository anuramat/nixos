{ config, ... }:
{
  plugins.neo-tree.enable = true;
  keymaps =
    let
      nmap = config.lib.cmd "n";
    in
    [
      (nmap "<leader>tt" "Neotree show last toggle" "Neotree: toggle")
      (nmap "<leader>tf" "Neotree focus last" "Neotree: focus")
      (nmap "<leader>tr" "Neotree show reveal" "Neotree: current file")
      (nmap "<leader>tg" "Neotree show git_status" "Neotree: git status")
    ];
}
