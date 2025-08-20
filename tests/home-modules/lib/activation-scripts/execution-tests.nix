# Execution tests: Real execution with jq/yq and verification of file system effects
{ testLib }:
let
  inherit (testLib) mkExecutionTest checkExecution mkRealActivationTest homeLib;
in
{
  # JSON Set: Test REAL mkJqActivationScript with comprehensive data
  testJsonSetExecution = {
    expr =
      let
        # Use the REAL activation script function
        dagEntry = homeLib.lib.home.json.set {
          simple = "value";
          number = 42;
          bool = true;
          "null" = null;
          nested = {
            level1 = {
              level2 = "deep";
              array = [1 2 3];
            };
          };
          special = "quotes\"and\\backslashes"; 
          unicode = "café🚀";
        } "test.json";
        
        # Test the ACTUAL generated activation script
        test = mkRealActivationTest "json-set-real" dagEntry 
          # Setup: no initial setup needed (script creates file from scratch)
          ''
            echo "No initial setup required for new JSON file test"
          ''
          # Verification: check results after real script execution
          ''
            echo "=== Verifying REAL JSON set activation script results ==="
            
            # The real activation script should have created/modified test.json
            [[ -f test.json ]] || { echo "Activation script didn't create target file"; exit 1; }
            
            # Verify it's valid JSON
            jq . test.json >/dev/null || { echo "Generated file is not valid JSON"; exit 1; }
            
            # Verify each field was set correctly by the REAL script
            [[ "$(jq -r '.simple' test.json)" == "value" ]] || { echo "Simple string not set by real script"; exit 1; }
            [[ "$(jq -r '.number' test.json)" == "42" ]] || { echo "Number not set by real script"; exit 1; }
            [[ "$(jq -r '.bool' test.json)" == "true" ]] || { echo "Boolean not set by real script"; exit 1; }
            [[ "$(jq -r '.null' test.json)" == "null" ]] || { echo "Null not set by real script"; exit 1; }
            
            # Verify nested structure  
            [[ "$(jq -r '.nested.level1.level2' test.json)" == "deep" ]] || { echo "Nested structure not created by real script"; exit 1; }
            [[ "$(jq -r '.nested.level1.array | length' test.json)" == "3" ]] || { echo "Array not handled by real script"; exit 1; }
            [[ "$(jq -r '.nested.level1.array[0]' test.json)" == "1" ]] || { echo "Array elements wrong in real script"; exit 1; }
            
            # Verify special characters handled correctly by real script
            [[ "$(jq -r '.special' test.json)" == 'quotes"and\backslashes' ]] || { echo "Special chars not handled by real script"; exit 1; }
            [[ "$(jq -r '.unicode' test.json)" == "café🚀" ]] || { echo "Unicode not handled by real script"; exit 1; }
            
            echo "REAL JSON set activation script verification passed!"
          '';
      in
      checkExecution test;
    expected = true;
  };

  # JSON Set on Existing: Test REAL script behavior with existing file 
  testJsonSetExistingExecution = {
    expr =
      let
        # Use REAL activation script function to add new data
        dagEntry = homeLib.lib.home.json.set {
          new = "value";
          additional = "field";
        } "test.json";
        
        # Test the ACTUAL generated activation script with pre-existing file
        test = mkRealActivationTest "json-set-existing-real" dagEntry
          # Setup: create existing JSON file that the real script will modify
          ''
            echo "=== Setting up existing JSON file ==="
            echo '{"existing":"data","nested":{"old":1,"preserved":"keep"}}' > test.json
            
            # Verify initial state
            [[ -f test.json ]] || { echo "Failed to create initial file"; exit 1; }
            [[ "$(jq -r '.existing' test.json)" == "data" ]] || { echo "Initial file setup wrong"; exit 1; }
            echo "Initial file ready for real script execution"
          ''
          # Verification: check results after real script has executed
          ''
            echo "=== Verifying REAL activation script results ==="
            
            # Verify the file still exists and is valid JSON after real script execution
            [[ -f test.json ]] || { echo "File lost after real script execution"; exit 1; }
            jq . test.json >/dev/null || { echo "File corrupted by real script"; exit 1; }
            
            # Verify existing data was preserved by the real script
            [[ "$(jq -r '.existing' test.json)" == "data" ]] || { echo "Existing data lost by real script"; exit 1; }
            [[ "$(jq -r '.nested.old' test.json)" == "1" ]] || { echo "Nested existing data lost by real script"; exit 1; }
            [[ "$(jq -r '.nested.preserved' test.json)" == "keep" ]] || { echo "Nested preserved data lost by real script"; exit 1; }
            
            # Verify new data was added by the real script
            [[ "$(jq -r '.new' test.json)" == "value" ]] || { echo "New data not added by real script"; exit 1; }
            [[ "$(jq -r '.additional' test.json)" == "field" ]] || { echo "Additional data not added by real script"; exit 1; }
            
            echo "REAL JSON set on existing file verification passed!"
          '';
      in
      checkExecution test;
    expected = true;
  };

  # JSON Merge: Test REAL mkJqActivationScript with merge operator
  testJsonMergeExecution = {
    expr =
      let
        # Use the REAL merge activation script function
        dagEntry = homeLib.lib.home.json.merge {
          nested = {
            overwrite = "new_value";
            added = "fresh";
            deep = {
              level = 2;
              new_key = "new";
            };
          };
          new_top = "value";
        } "test.json";
        
        test = mkRealActivationTest "json-merge-real" dagEntry
          # Setup: create complex base JSON to test merge semantics thoroughly
          ''
            echo "=== Setting up base JSON for merge test ==="
            cat > test.json << 'EOF'
{
  "existing": "original",
  "nested": {
    "preserve": "keep_this",
    "overwrite": "old_value",
    "deep": {
      "level": 1,
      "existing_array": [1, 2]
    }
  },
  "array_base": ["a", "b"],
  "null_field": null,
  "bool_field": true
}
EOF
            
            # Verify initial state
            [[ "$(jq -r '.existing' test.json)" == "original" ]] || { echo "Initial state wrong"; exit 1; }
            [[ "$(jq -r '.nested.preserve' test.json)" == "keep_this" ]] || { echo "Initial nested setup wrong"; exit 1; }
            echo "Base JSON file ready for merge"
          ''
          # Verification: check that real merge script preserved and merged correctly
          ''
            echo "=== Verifying REAL JSON merge activation script results ==="
            
            # Verify the file still exists and is valid JSON
            [[ -f test.json ]] || { echo "File lost after real merge script"; exit 1; }
            jq . test.json >/dev/null || { echo "File corrupted by real merge script"; exit 1; }
            
            # Verify existing data was preserved during merge
            [[ "$(jq -r '.existing' test.json)" == "original" ]] || { echo "Existing field lost during real merge"; exit 1; }
            [[ "$(jq -r '.nested.preserve' test.json)" == "keep_this" ]] || { echo "Preserved nested field lost in real merge"; exit 1; }
            
            # Verify new data was merged in by real script
            [[ "$(jq -r '.nested.overwrite' test.json)" == "new_value" ]] || { echo "Nested field not overwritten by real merge"; exit 1; }
            [[ "$(jq -r '.nested.added' test.json)" == "fresh" ]] || { echo "New nested field not added by real merge"; exit 1; }
            [[ "$(jq -r '.new_top' test.json)" == "value" ]] || { echo "New top-level field not added by real merge"; exit 1; }
            
            # Verify deep merge behavior
            [[ "$(jq -r '.nested.deep.level' test.json)" == "2" ]] || { echo "Deep merge failed - level not updated by real script"; exit 1; }
            [[ "$(jq -r '.nested.deep.new_key' test.json)" == "new" ]] || { echo "Deep merge failed - new key not added by real script"; exit 1; }
            
            echo "REAL JSON merge activation script verification passed!"
          '';
      in
      checkExecution test;
    expected = true;
  };

  # YAML Set: Test REAL mkYqActivationScript comprehensive operations
  testYamlSetExecution = {
    expr =
      let
        # Use the REAL YAML activation script function
        dagEntry = homeLib.lib.home.yaml.set {
          "config.database.host" = "localhost";
          "config.database.port" = 5432;
          "config.database.ssl" = true;
          "config.database.timeout" = null;
          "services.list" = ["web" "api" "cache"];
          "services.ports" = [8080 8081 8082];
          "applications.frontend.build.environment" = "production";
          "applications.frontend.build.optimize" = true;
          "special.quotes" = "He said \"hello\"";
          "special.unicode" = "café 🚀";
          "special.multiline" = "line1\nline2";
          "mixed.string_val" = "text";
          "mixed.int_val" = 42;
          "mixed.float_val" = 3.14;
          "mixed.bool_val" = false;
        } "test.yaml";
        
        test = mkRealActivationTest "yaml-set-real" dagEntry
          # Setup: minimal setup, let the real script handle YAML initialization
          ''
            echo "=== Setting up for REAL YAML set test ==="
            echo "Real YAML script will handle file initialization"
          ''
          # Verification: check that all YAML operations worked correctly
          ''
            echo "=== Verifying REAL YAML set activation script results ==="
            
            # Verify the file exists and is valid YAML
            [[ -f test.yaml ]] || { echo "YAML file not created by real script"; exit 1; }
            yq eval '.' test.yaml >/dev/null || { echo "Generated file is not valid YAML"; exit 1; }
            
            # Verify basic nested path setting
            [[ "$(yq eval '.config.database.host' test.yaml)" == "localhost" ]] || { echo "Host not set by real script"; exit 1; }
            [[ "$(yq eval '.config.database.port' test.yaml)" == "5432" ]] || { echo "Port not set by real script"; exit 1; }
            [[ "$(yq eval '.config.database.ssl' test.yaml)" == "true" ]] || { echo "Boolean not set by real script"; exit 1; }
            [[ "$(yq eval '.config.database.timeout' test.yaml)" == "null" ]] || { echo "Null not set by real script"; exit 1; }
            
            # Verify arrays were set correctly
            [[ "$(yq eval '.services.list | length' test.yaml)" == "3" ]] || { echo "Array length wrong in real script"; exit 1; }
            [[ "$(yq eval '.services.list[0]' test.yaml)" == "web" ]] || { echo "Array first element wrong in real script"; exit 1; }
            [[ "$(yq eval '.services.list[2]' test.yaml)" == "cache" ]] || { echo "Array third element wrong in real script"; exit 1; }
            [[ "$(yq eval '.services.ports[1]' test.yaml)" == "8081" ]] || { echo "Numeric array wrong in real script"; exit 1; }
            
            # Verify deep nested structures
            [[ "$(yq eval '.applications.frontend.build.environment' test.yaml)" == "production" ]] || { echo "Deep nested string failed in real script"; exit 1; }
            [[ "$(yq eval '.applications.frontend.build.optimize' test.yaml)" == "true" ]] || { echo "Deep nested boolean failed in real script"; exit 1; }
            
            # Verify special characters and escaping
            [[ "$(yq eval '.special.quotes' test.yaml)" == 'He said "hello"' ]] || { echo "Quote escaping failed in real script"; exit 1; }
            [[ "$(yq eval '.special.unicode' test.yaml)" == "café 🚀" ]] || { echo "Unicode handling failed in real script"; exit 1; }
            
            # Verify mixed data types
            [[ "$(yq eval '.mixed.string_val' test.yaml)" == "text" ]] || { echo "Mixed string failed in real script"; exit 1; }
            [[ "$(yq eval '.mixed.int_val' test.yaml)" == "42" ]] || { echo "Mixed int failed in real script"; exit 1; }
            [[ "$(yq eval '.mixed.float_val' test.yaml)" == "3.14" ]] || { echo "Mixed float failed in real script"; exit 1; }
            [[ "$(yq eval '.mixed.bool_val' test.yaml)" == "false" ]] || { echo "Mixed bool failed in real script"; exit 1; }
            
            echo "REAL YAML set activation script verification passed!"
          '';
      in
      checkExecution test;
    expected = true;
  };

  # Generic Copy: Test REAL mkGenericActivationScript file copying
  testGenericCopyExecution = {
    expr =
      let
        # Use the REAL generic activation script function with relative paths
        dagEntry = homeLib.lib.home.mkGenericActivationScript "source-file" "target-file";
        
        test = mkRealActivationTest "generic-copy-real" dagEntry
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
