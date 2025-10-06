# Execution tests: Real execution with jq/yq and verification of file system effects
{ testLib }:
let
  inherit (testLib)
    checkExecution
    mkRealActivationTest
    mkPureActivationTest
    homeLib
    ;
in
{
  # JSON Set: Test REAL mkJqActivationScript with comprehensive data (Pure Nix)
  testJsonSetExecution = {
    expr =
      let
        # Input data to set (using flat JSON paths as expected by mkJqActivationScript)
        inputData = {
          "simple" = "value";
          "number" = 42;
          "bool" = true;
          "null" = null;
          "nested.level1.level2" = "deep";
          "nested.level1.array" = [
            1
            2
            3
          ];
          "special" = "quotes\"and\\backslashes";
          "unicode" = "café🚀";
        };

        # Use the REAL activation script function
        dagEntry = homeLib.lib.home.json.set inputData "test.json";

        # Expected result: flat paths get converted to nested JSON structure
        expectedData = {
          simple = "value";
          number = 42;
          bool = true;
          "null" = null;
          nested = {
            level1 = {
              level2 = "deep";
              array = [
                1
                2
                3
              ];
            };
          };
          special = "quotes\"and\\backslashes";
          unicode = "café🚀";
        };
      in
      # Pure Nix test - no bash needed!
      mkPureActivationTest "json-set-pure" dagEntry "test.json" null expectedData;
    expected = true;
  };

  # JSON Set on Existing: Test REAL script behavior with existing file (Pure Nix)
  testJsonSetExistingExecution = {
    expr =
      let
        # Setup data that will be in the file initially
        setupData = {
          existing = "data";
          nested = {
            old = 1;
            preserved = "keep";
          };
        };

        # New data to set (using flat JSON paths)
        newData = {
          "new" = "value";
          "additional" = "field";
        };

        # Use REAL activation script function to set new data
        dagEntry = homeLib.lib.home.json.set newData "test.json";

        # Expected result: set operation adds new data to existing data (jq set merges at JSON level)
        expectedData = {
          existing = "data";
          nested = {
            old = 1;
            preserved = "keep";
          };
          new = "value";
          additional = "field";
        };
      in
      mkPureActivationTest "json-set-existing-pure" dagEntry "test.json" setupData expectedData;
    expected = true;
  };

  # YAML Set: Test REAL mkYqActivationScript comprehensive operations (Pure Nix)
  testYamlSetExecution = {
    expr =
      let
        # Input data to set in YAML
        inputData = {
          "config.database.host" = "localhost";
          "config.database.port" = 5432;
          "config.database.ssl" = true;
          "config.database.timeout" = null;
          "services.list" = [
            "web"
            "api"
            "cache"
          ];
          "services.ports" = [
            8080
            8081
            8082
          ];
          "applications.frontend.build.environment" = "production";
          "applications.frontend.build.optimize" = true;
          "special.quotes" = "He said \"hello\"";
          "special.unicode" = "café 🚀";
          "special.multiline" = "line1\nline2";
          "mixed.string_val" = "text";
          "mixed.int_val" = 42;
          "mixed.float_val" = 3.14;
          "mixed.bool_val" = false;
        };

        # Use the REAL YAML activation script function
        dagEntry = homeLib.lib.home.yaml.set inputData "test.yaml";

        # Expected result: yq converts dotted keys to nested structure
        expectedData = {
          config = {
            database = {
              host = "localhost";
              port = 5432;
              ssl = true;
              timeout = null;
            };
          };
          services = {
            list = [
              "web"
              "api"
              "cache"
            ];
            ports = [
              8080
              8081
              8082
            ];
          };
          applications = {
            frontend = {
              build = {
                environment = "production";
                optimize = true;
              };
            };
          };
          special = {
            quotes = "He said \"hello\"";
            unicode = "café 🚀";
            multiline = "line1\nline2";
          };
          mixed = {
            string_val = "text";
            int_val = 42;
            float_val = 3.14;
            bool_val = false;
          };
        };
      in
      # Pure Nix test with YAML converted to JSON for comparison
      mkPureActivationTest "yaml-set-pure" dagEntry "test.yaml" null expectedData;
    expected = true;
  };

  # Generic Copy: Test REAL mkGenericActivationScript file copying
  testGenericCopyExecution = {
    expr =
      let
        # Use the REAL generic activation script function with relative paths
        dagEntry = homeLib.lib.home.mkGenericActivationScript "source-file" "target-file";

        test =
          mkRealActivationTest "generic-copy-real" dagEntry
            # Setup: create source file that the real script will copy
            ''
              echo "=== Setting up source file for REAL generic script test ==="

              # Create the source file with test content (in current directory)
              echo "test content from real script" > source-file

              # Verify source file exists
              [[ -f "source-file" ]] || { echo "Failed to create source file"; exit 1; }
              [[ "$(cat source-file)" == "test content from real script" ]] || { echo "Source content wrong"; exit 1; }

              echo "Source file ready for real script execution"
            ''
            # Verification: check that real script copied file correctly
            ''
              echo "=== Verifying REAL generic activation script results ==="

              # Verify target file was created by the real script
              [[ -f "target-file" ]] || { echo "Target file not created by real script"; exit 1; }

              # Verify content was copied correctly by real script
              content=$(cat target-file)
              [[ "$content" == "test content from real script" ]] || { echo "Content not copied correctly by real script: $content"; exit 1; }

              # Verify source file still exists (copy, not move)
              [[ -f "source-file" ]] || { echo "Source file was deleted by real script"; exit 1; }

              echo "REAL generic activation script verification passed!"
            '';
      in
      checkExecution test;
    expected = true;
  };
}
