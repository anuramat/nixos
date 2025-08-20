{ pkgs, lib }:
let
  # Mock config for testing - provides minimal structure needed by lib.nix
  mockConfig = {
    xdg.stateHome = "/tmp/test-state";
  };

  # Mock lib with hm.dag functionality (similar to tests/hax/home.nix)
  mockLib = lib // {
    hm.dag = {
      entryAfter = deps: text: {
        _type = "dag-entry";
        data = text;
        after = deps;
        before = [ ];
      };
    };
  };

  # Import the lib functions we want to test
  homeLib = import ../../../../home-modules/default/lib.nix {
    pkgs = pkgs;
    lib = mockLib;
    config = mockConfig;
  };
in
{
  inherit mockConfig mockLib homeLib;

  # Test data for operations
  testJsonData = {
    simple = {
      "key" = "value";
    };
    nested = {
      "level1" = {
        "level2" = "nested-value";
      };
    };
    array = {
      "items" = [
        "a"
        "b"
        "c"
      ];
    };
    mixed = {
      "string" = "text";
      "number" = 42;
      "bool" = true;
      "null" = null;
      "nested" = {
        "inner" = "value";
      };
    };
  };

  testYamlData = {
    simple = {
      "key" = "value";
    };
    nested = {
      "config" = {
        "setting" = "enabled";
      };
    };
  };

  # Helper to create execution tests that actually run the scripts
  # Fixed interface: removed unused 'script' parameter
  mkExecutionTest = name: testScript:
    let
      drv = pkgs.runCommand "test-${name}" {
        buildInputs = with pkgs; [
          jq
          yq-go
          moreutils
          bash
          coreutils
          diffutils
        ];
      } ''
        set -euo pipefail

        # Create test workspace
        export HOME=$PWD
        cd $HOME

        # Mock the run function that home-manager provides
        run() { "$@"; }
        export -f run

        # Run the test script
        ${testScript}

        # Success marker
        echo "PASS" > $out
      '';
    in
    drv;

  # Helper to check if execution test passed
  checkExecution = drv: builtins.pathExists drv;

  # Re-export everything for easy access
  inherit lib pkgs;
}