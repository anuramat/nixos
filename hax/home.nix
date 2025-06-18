_: homelib: {
  removeBrokenLinks =
    path:
    homelib.hm.dag.entryBefore [ "writeBoundary" ] # bash
      ''
        args=("${path}" -maxdepth 1 -xtype l)
        [ -z "''${DRY_RUN:+set}" ] && args+=(-delete) 
        [ -n "''${VERBOSE:+set}" ] && args+=(-print)
        run find "''${args[@]}"
      '';
}
