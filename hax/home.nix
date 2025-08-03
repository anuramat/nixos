_: homelib: {
  removeBrokenLinks =
    path:
    homelib.hm.dag.entryAfter [ "writeBoundary" ] # bash
      ''
        args=("${path}" -maxdepth 1 -xtype l)
        [ -z "''${DRY_RUN:+set}" ] && args+=(-delete)
        [ -n "''${VERBOSE:+set}" ] && args+=(-print)
        run find "''${args[@]}"
      '';
}
