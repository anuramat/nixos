{ lib, ... }:
with lib;
{
  # uniq -- one definition
  options = {
    server = mkOption {
      type = with types; uniq bool;
      description = "Disables all the GUI stuff etc";
    };
    user = mkOption {
      type = with types; uniq str;
      description = "Primary user";
    };
  };
}
