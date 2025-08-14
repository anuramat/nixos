{ pkgs, lib }:
let
  # Mock homelib with dag functionality
  mockHomelib = {
    hm.dag = {
      entryAfter = deps: text: {
        _type = "dag-entry";
        data = text;
        after = deps;
        before = [ ];
      };
    };
  };

  hax = import ../../../hax/home.nix { } mockHomelib;
in
{
  # Test removeBrokenLinks
  testRemoveBrokenLinks = {
    expr = hax.removeBrokenLinks "/home/user/.config";
    expected = {
      _type = "dag-entry";
      data = ''
        args=("/home/user/.config" -maxdepth 1 -xtype l)
        [ -z "''${DRY_RUN:+set}" ] && args+=(-delete)
        [ -n "''${VERBOSE:+set}" ] && args+=(-print)
        run find "''${args[@]}"
      '';
      after = [ "writeBoundary" ];
      before = [ ];
    };
  };

  # Test removeBrokenLinks with different path
  testRemoveBrokenLinksDifferentPath = {
    expr = hax.removeBrokenLinks "/tmp/test-dir";
    expected = {
      _type = "dag-entry";
      data = ''
        args=("/tmp/test-dir" -maxdepth 1 -xtype l)
        [ -z "''${DRY_RUN:+set}" ] && args+=(-delete)
        [ -n "''${VERBOSE:+set}" ] && args+=(-print)
        run find "''${args[@]}"
      '';
      after = [ "writeBoundary" ];
      before = [ ];
    };
  };

  # Test that removeBrokenLinks creates a DAG entry after writeBoundary
  testRemoveBrokenLinksOrdering = {
    expr =
      let
        result = hax.removeBrokenLinks "/path";
      in
      {
        hasAfterDep = builtins.elem "writeBoundary" result.after;
        afterLength = builtins.length result.after;
      };
    expected = {
      hasAfterDep = true;
      afterLength = 1;
    };
  };

  # Test removeBrokenLinks with path containing spaces (should be properly quoted)
  testRemoveBrokenLinksWithSpaces = {
    expr =
      let
        result = hax.removeBrokenLinks "/path with spaces";
      in
      # Check that the path is properly quoted in the command
      lib.strings.hasInfix ''"/path with spaces"'' result.data;
    expected = true;
  };

  # Test removeBrokenLinks command structure
  testRemoveBrokenLinksCommandStructure = {
    expr =
      let
        result = hax.removeBrokenLinks "/test";
        lines = lib.splitString "\n" result.data;
      in
      {
        # Check key parts of the generated script
        hasArgsInit = lib.strings.hasPrefix "args=" (builtins.elemAt lines 0);
        hasDryRunCheck = lib.strings.hasInfix "DRY_RUN" result.data;
        hasVerboseCheck = lib.strings.hasInfix "VERBOSE" result.data;
        hasDeleteFlag = lib.strings.hasInfix "-delete" result.data;
        hasPrintFlag = lib.strings.hasInfix "-print" result.data;
        hasFindCommand = lib.strings.hasInfix "run find" result.data;
      };
    expected = {
      hasArgsInit = true;
      hasDryRunCheck = true;
      hasVerboseCheck = true;
      hasDeleteFlag = true;
      hasPrintFlag = true;
      hasFindCommand = true;
    };
  };

  # Test removeBrokenLinks uses correct find options
  testRemoveBrokenLinksFindOptions = {
    expr =
      let
        result = hax.removeBrokenLinks "/dir";
      in
      {
        hasMaxDepth = lib.strings.hasInfix "-maxdepth 1" result.data;
        hasXtype = lib.strings.hasInfix "-xtype l" result.data;
      };
    expected = {
      hasMaxDepth = true;
      hasXtype = true;
    };
  };
}
