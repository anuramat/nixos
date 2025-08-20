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
  mkExecutionTest =
    name: testScript:
    let
      drv =
        pkgs.runCommand "test-${name}"
          {
            buildInputs = with pkgs; [
              jq
              yq-go
              moreutils
              bash
              coreutils
              diffutils
            ];
          }
          ''
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

  # NEW: Helper to extract and execute actual DAG activation scripts
  # This tests the REAL generated scripts instead of hardcoded approximations
  mkRealActivationTest = name: dagEntry: setupScript: verificationScript:
    let
      # Extract the actual bash script from the DAG entry
      realScript = dagEntry.data;
      
      drv = pkgs.runCommand "test-real-${name}" {
        buildInputs = with pkgs; [
          jq yq-go moreutils bash coreutils diffutils
        ];
      } ''
        set -euo pipefail
        
        # Create test workspace
        export HOME=$PWD
        cd $HOME
        
        # Mock the run function that home-manager provides
        run() { "$@"; }
        export -f run
        
        echo "=== Running setup for ${name} ==="
        
        # Run setup (e.g., create initial files)
        ${setupScript}
        
        echo "=== Executing REAL activation script for ${name} ==="
        
        # Execute the ACTUAL generated activation script
        ${realScript}
        
        echo "=== Real script execution completed, running verification ==="
        
        # Run verification to check the results
        ${verificationScript}
        
        # Success marker
        echo "PASS" > $out
      '';
    in
    drv;

  # Test helper functions are defined directly in this attribute set
  
  # Re-export everything for easy access
  inherit lib pkgs;
}
