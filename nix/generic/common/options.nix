{ lib, ... }:
with lib;
{
  # uniq -- one definition
  options = {
    user = mkOption {
      type = with types; uniq str;
      description = "Primary user";
    };
  };
}
