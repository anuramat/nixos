{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.todo;
in
{
  options.programs.todo = {
    enable = lib.mkEnableOption "todo.txt CLI";
    file = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.todo ];
      sessionVariables.TODO_FILE = cfg.file;
    };
    # for files with the merge=todo git attribute
    programs.git.settings.merge.todo.driver = "${lib.getExe pkgs.todo} merge %A %O %B";
  };
}
