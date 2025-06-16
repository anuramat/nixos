{
  programs = {
    ripgrep = {
      enable = true;
      arguments = [
        # search over working tree

        # include .*
        "--hidden"
        # symlinks
        "--follow"
        # revert with -s for sensitive
        "--smart-case"

        # with exceptions:

        # VCS
        "--glob=!{.git,.svn}"
        # codegen
        "--glob=!*.pb.go"
      ];
    };

    ripgrep-all = {
      enable = true;
    };
  };
}
