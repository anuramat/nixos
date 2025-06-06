{ lib, ... }:
with lib;
{
  options = {
    machine = mkOption {
      type = types.submodule {
        options = {
          remote = mkOption {
            type = with types; uniq bool;
            description = "Doesn't have a screen";
          };
          portable = mkOption {
            type = with types; uniq bool;
            description = "Can run on a battery";
          };
          static = mkOption {
            type = with types; uniq bool;
            description = "Sits on your desk (most of the time)";
          };
        };
      };
    };
    # user = mkOption {
    #   type = types.submodule {
    #     options = {
    #       username = mkOption {
    #         type = with types; uniq str;
    #         description = "System username";
    #       };
    #       fullname = mkOption {
    #         type = with types; uniq str;
    #         description = "Full name (first last)";
    #       };
    #       email = mkOption {
    #         type = with types; uniq str;
    #         description = "Email address";
    #       };
    #     };
    #   };
    #   description = "Primary user";
    # };
  };
}
