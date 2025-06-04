{ lib, ... }:
with lib;
{
  options = {
    user = mkOption {
      type = types.submodule {
        options = {
          username = mkOption {
            type = with types; uniq str;
            description = "System username";
          };
          fullname = mkOption {
            type = with types; uniq str;
            description = "Full name (first last)";
          };
          email = mkOption {
            type = with types; uniq str;
            description = "Email address";
          };
        };
      };
      description = "Primary user";
    };
  };
}
