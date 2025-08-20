# Execution tests: Real execution with jq/yq and verification of file system effects
{ testLib }:
let
  inherit (testLib) mkExecutionTest checkExecution;
in
{
  # JSON Set: Create file with data (comprehensive execution test)
  testJsonSetExecution = {
    expr =
      let
        test = mkExecutionTest "json-set" ''
          echo "=== Testing JSON set operation (comprehensive) ==="

          # Create initial empty JSON file (simulating script behavior)
          echo '{}' > test.json
          [[ -f test.json ]] || { echo "Failed to create initial file"; exit 1; }
          [[ "$(jq -c . test.json)" == "{}" ]] || { echo "Initial file not empty JSON"; exit 1; }

          # Test 1: Simple key-value pairs
          echo '{"simple":"value","number":42,"bool":true,"null":null}' > source1.json
          jq --slurpfile arg source1.json '.simple = $arg[0].simple | .number = $arg[0].number | .bool = $arg[0].bool | .null = $arg[0].null' test.json > temp.json
          mv temp.json test.json

          # Verify each field individually
          [[ "$(jq -r '.simple' test.json)" == "value" ]] || { echo "Simple string not set"; exit 1; }
          [[ "$(jq -r '.number' test.json)" == "42" ]] || { echo "Number not set"; exit 1; }
          [[ "$(jq -r '.bool' test.json)" == "true" ]] || { echo "Boolean not set"; exit 1; }
          [[ "$(jq -r '.null' test.json)" == "null" ]] || { echo "Null not set"; exit 1; }

          # Test 2: Nested object structures  
          echo '{"nested":{"level1":{"level2":"deep","array":[1,2,3]}}}' > source2.json
          jq --slurpfile arg source2.json '.nested = $arg[0].nested' test.json > temp.json
          mv temp.json test.json

          # Verify nested structure preservation
          [[ "$(jq -r '.nested.level1.level2' test.json)" == "deep" ]] || { echo "Deep nesting not preserved"; exit 1; }
          [[ "$(jq -r '.nested.level1.array | length' test.json)" == "3" ]] || { echo "Array length wrong"; exit 1; }
          [[ "$(jq -r '.nested.level1.array[0]' test.json)" == "1" ]] || { echo "Array elements wrong"; exit 1; }

          # Test 3: Overwriting existing values (set semantics)
          echo '{"simple":"overwritten","new":"added"}' > source3.json
          jq --slurpfile arg source3.json '.simple = $arg[0].simple | .new = $arg[0].new' test.json > temp.json
          mv temp.json test.json

          # Verify overwrite behavior
          [[ "$(jq -r '.simple' test.json)" == "overwritten" ]] || { echo "Value not overwritten"; exit 1; }
          [[ "$(jq -r '.new' test.json)" == "added" ]] || { echo "New value not added"; exit 1; }
          # Original nested data should still exist
          [[ "$(jq -r '.nested.level1.level2' test.json)" == "deep" ]] || { echo "Existing nested data lost"; exit 1; }

          # Test 4: Special characters and escaping
          echo '{"special":"quotes\"and\\backslashes","unicode":"café🚀"}' > source4.json
          jq --slurpfile arg source4.json '.special = $arg[0].special | .unicode = $arg[0].unicode' test.json > temp.json
          mv temp.json test.json

          # Verify special character handling
          [[ "$(jq -r '.special' test.json)" == 'quotes"and\backslashes' ]] || { echo "Special chars not handled"; exit 1; }
          [[ "$(jq -r '.unicode' test.json)" == "café🚀" ]] || { echo "Unicode not handled"; exit 1; }

          # Test 5: JSON path operations (dot notation)
          echo '{"config.database.host":"localhost","config.database.port":5432}' > source5.json
          jq --slurpfile arg source5.json '."config.database.host" = $arg[0]."config.database.host" | ."config.database.port" = $arg[0]."config.database.port"' test.json > temp.json
          mv temp.json test.json

          # Verify dot notation keys are handled correctly
          [[ "$(jq -r '."config.database.host"' test.json)" == "localhost" ]] || { echo "Dot notation key not set"; exit 1; }
          [[ "$(jq -r '."config.database.port"' test.json)" == "5432" ]] || { echo "Dot notation number not set"; exit 1; }

          # Final verification: ensure valid JSON
          jq . test.json >/dev/null || { echo "Final result is invalid JSON"; exit 1; }
          
          echo "JSON set operation comprehensive test passed!"
        '';
      in
      checkExecution test;
    expected = true;
  };

  # JSON Set on Existing: Merge into existing file
  testJsonSetExistingExecution = {
    expr =
      let
        test = mkExecutionTest "json-set-existing" ''
          # Test JSON set operation on existing file
          echo "=== Testing JSON set on existing file ==="

          # Create existing JSON file
          echo '{"existing":"data","nested":{"old":1}}' > test.json

          # Create source for new data
          echo '{"new":"value"}' > source.json

          # Perform jq operation (set operation preserves existing data)
          jq --slurpfile arg source.json '. = . + $arg[0]' test.json > temp.json
          mv temp.json test.json

          # Verify result contains both old and new data
          existing=$(jq -r '.existing' test.json)
          new=$(jq -r '.new' test.json)
          old=$(jq -r '.nested.old' test.json)

          [[ "$existing" == "data" ]] || { echo "Lost existing data"; exit 1; }
          [[ "$new" == "value" ]] || { echo "New data not added"; exit 1; }
          [[ "$old" == "1" ]] || { echo "Nested data corrupted"; exit 1; }

          echo "JSON set on existing file works!"
        '';
      in
      checkExecution test;
    expected = true;
  };

  # JSON Merge: Use merge operator (comprehensive execution test)
  testJsonMergeExecution = {
    expr =
      let
        test = mkExecutionTest "json-merge" ''
          echo "=== Testing JSON merge operation (comprehensive) ==="

          # Create complex base JSON to test merge semantics thoroughly
          echo '{
            "existing": "original",
            "nested": {
              "preserve": "keep_this",
              "overwrite": "old_value",
              "deep": {
                "level": 1,
                "array": [1, 2]
              }
            },
            "array_base": ["a", "b"],
            "null_field": null,
            "bool_field": true
          }' > test.json

          # Verify initial state
          [[ "$(jq -r '.existing' test.json)" == "original" ]] || { echo "Initial state wrong"; exit 1; }

          # Test 1: Basic merge with object overlay
          echo '{
            "nested": {
              "overwrite": "new_value",
              "added": "fresh",
              "deep": {
                "level": 2,
                "new_key": "new"
              }
            },
            "new_top": "value"
          }' > merge1.json

          # Perform merge operation (*= operator)
          jq --slurpfile arg merge1.json '. *= $arg[0]' test.json > temp.json
          mv temp.json test.json

          # Verify merge behavior - deep object merging
          [[ "$(jq -r '.existing' test.json)" == "original" ]] || { echo "Existing field lost during merge"; exit 1; }
          [[ "$(jq -r '.nested.preserve' test.json)" == "keep_this" ]] || { echo "Preserved nested field lost"; exit 1; }
          [[ "$(jq -r '.nested.overwrite' test.json)" == "new_value" ]] || { echo "Nested field not overwritten"; exit 1; }
          [[ "$(jq -r '.nested.added' test.json)" == "fresh" ]] || { echo "New nested field not added"; exit 1; }
          [[ "$(jq -r '.new_top' test.json)" == "value" ]] || { echo "New top-level field not added"; exit 1; }

          # Verify deep merge behavior
          [[ "$(jq -r '.nested.deep.level' test.json)" == "2" ]] || { echo "Deep merge failed - level not updated"; exit 1; }
          [[ "$(jq -r '.nested.deep.new_key' test.json)" == "new" ]] || { echo "Deep merge failed - new key not added"; exit 1; }

          # Test 2: Array handling in merge (arrays are replaced, not merged)
          echo '{
            "array_base": ["x", "y", "z"],
            "nested": {
              "deep": {
                "array": [3, 4, 5]
              }
            }
          }' > merge2.json

          jq --slurpfile arg merge2.json '. *= $arg[0]' test.json > temp.json
          mv temp.json test.json

          # Verify array replacement behavior
          [[ "$(jq -r '.array_base | length' test.json)" == "3" ]] || { echo "Array length wrong after merge"; exit 1; }
          [[ "$(jq -r '.array_base[0]' test.json)" == "x" ]] || { echo "Array not replaced correctly"; exit 1; }
          [[ "$(jq -r '.nested.deep.array[0]' test.json)" == "3" ]] || { echo "Nested array not replaced"; exit 1; }

          # Test 3: Type changes during merge
          echo '{
            "null_field": "now_string",
            "bool_field": 42,
            "existing": {
              "converted": "to_object"
            }
          }' > merge3.json

          jq --slurpfile arg merge3.json '. *= $arg[0]' test.json > temp.json
          mv temp.json test.json

          # Verify type conversion handling
          [[ "$(jq -r '.null_field' test.json)" == "now_string" ]] || { echo "Null to string conversion failed"; exit 1; }
          [[ "$(jq -r '.bool_field' test.json)" == "42" ]] || { echo "Bool to number conversion failed"; exit 1; }
          [[ "$(jq -r '.existing.converted' test.json)" == "to_object" ]] || { echo "String to object conversion failed"; exit 1; }

          # Test 4: Empty object merge (should be no-op)
          cp test.json before_empty.json
          echo '{}' > empty.json
          jq --slurpfile arg empty.json '. *= $arg[0]' test.json > temp.json
          mv temp.json test.json

          # Verify empty merge is identity operation
          diff -q before_empty.json test.json || { echo "Empty merge changed file content"; exit 1; }

          # Test 5: Complex nested structure merge
          echo '{
            "config": {
              "database": {
                "connections": {
                  "primary": {
                    "host": "db1.example.com",
                    "port": 5432
                  },
                  "replica": {
                    "host": "db2.example.com"
                  }
                }
              }
            }
          }' > complex.json

          jq --slurpfile arg complex.json '. *= $arg[0]' test.json > temp.json
          mv temp.json test.json

          # Verify complex structure preserved
          [[ "$(jq -r '.config.database.connections.primary.host' test.json)" == "db1.example.com" ]] || { echo "Complex nested merge failed"; exit 1; }
          [[ "$(jq -r '.config.database.connections.primary.port' test.json)" == "5432" ]] || { echo "Complex nested merge missing field"; exit 1; }

          # Final verification: ensure valid JSON and all previous data preserved
          jq . test.json >/dev/null || { echo "Final result is invalid JSON"; exit 1; }
          [[ "$(jq -r '.nested.preserve' test.json)" == "keep_this" ]] || { echo "Original preserved field lost in complex merge"; exit 1; }

          echo "JSON merge operation comprehensive test passed!"
        '';
      in
      checkExecution test;
    expected = true;
  };

  # YAML Set: Test comprehensive YAML operations
  testYamlSetExecution = {
    expr =
      let
        test = mkExecutionTest "yaml-set" ''
          echo "=== Testing YAML set operation (comprehensive) ==="

          # Test 1: Empty file initialization (what the activation script does)
          echo '{}' > test.yaml
          [[ -f test.yaml ]] || { echo "Failed to create YAML file"; exit 1; }
          yq eval '.' test.yaml >/dev/null || { echo "Initial YAML invalid"; exit 1; }

          # Test 2: Basic nested path setting
          yq eval '.config.database.host = "localhost"' -i test.yaml
          yq eval '.config.database.port = 5432' -i test.yaml
          yq eval '.config.database.ssl = true' -i test.yaml
          yq eval '.config.database.timeout = null' -i test.yaml

          # Verify basic structure
          [[ "$(yq eval '.config.database.host' test.yaml)" == "localhost" ]] || { echo "Host not set"; exit 1; }
          [[ "$(yq eval '.config.database.port' test.yaml)" == "5432" ]] || { echo "Port not set"; exit 1; }
          [[ "$(yq eval '.config.database.ssl' test.yaml)" == "true" ]] || { echo "Boolean not set"; exit 1; }
          [[ "$(yq eval '.config.database.timeout' test.yaml)" == "null" ]] || { echo "Null not set"; exit 1; }

          # Test 3: Array operations
          yq eval '.services.list = ["web", "api"]' -i test.yaml
          yq eval '.services.list += ["cache"]' -i test.yaml
          yq eval '.services.ports = [8080, 8081, 8082]' -i test.yaml

          # Verify arrays
          [[ "$(yq eval '.services.list | length' test.yaml)" == "3" ]] || { echo "Array length wrong"; exit 1; }
          [[ "$(yq eval '.services.list[0]' test.yaml)" == "web" ]] || { echo "Array first element wrong"; exit 1; }
          [[ "$(yq eval '.services.list[2]' test.yaml)" == "cache" ]] || { echo "Array append failed"; exit 1; }
          [[ "$(yq eval '.services.ports[1]' test.yaml)" == "8081" ]] || { echo "Numeric array wrong"; exit 1; }

          # Test 4: Complex nested structures
          yq eval '.applications.frontend.build.environment = "production"' -i test.yaml
          yq eval '.applications.frontend.build.optimize = true' -i test.yaml
          yq eval '.applications.backend.database.connections.primary.host = "db1.local"' -i test.yaml
          yq eval '.applications.backend.database.connections.primary.credentials.username = "admin"' -i test.yaml

          # Verify deep nesting
          [[ "$(yq eval '.applications.frontend.build.environment' test.yaml)" == "production" ]] || { echo "Deep nested string failed"; exit 1; }
          [[ "$(yq eval '.applications.backend.database.connections.primary.host' test.yaml)" == "db1.local" ]] || { echo "Very deep nesting failed"; exit 1; }

          # Test 5: Special characters and escaping in YAML
          yq eval '.special.quotes = "He said \"hello\""' -i test.yaml
          yq eval '.special.unicode = "café 🚀"' -i test.yaml
          yq eval '.special.multiline = "line1\nline2"' -i test.yaml
          yq eval '.special."key.with.dots" = "dotted_key"' -i test.yaml

          # Verify special character handling
          [[ "$(yq eval '.special.quotes' test.yaml)" == 'He said "hello"' ]] || { echo "Quote escaping failed"; exit 1; }
          [[ "$(yq eval '.special.unicode' test.yaml)" == "café 🚀" ]] || { echo "Unicode handling failed"; exit 1; }
          [[ "$(yq eval '.special."key.with.dots"' test.yaml)" == "dotted_key" ]] || { echo "Dotted key failed"; exit 1; }

          # Test 6: Overwriting existing values (YAML set semantics)
          original_host=$(yq eval '.config.database.host' test.yaml)
          yq eval '.config.database.host = "newhost.example.com"' -i test.yaml
          new_host=$(yq eval '.config.database.host' test.yaml)

          [[ "$original_host" == "localhost" ]] || { echo "Original value check failed"; exit 1; }
          [[ "$new_host" == "newhost.example.com" ]] || { echo "Value not overwritten"; exit 1; }
          # Ensure other values preserved
          [[ "$(yq eval '.config.database.port' test.yaml)" == "5432" ]] || { echo "Sibling value lost during overwrite"; exit 1; }

          # Test 7: Mixed data types in same structure
          yq eval '.mixed.string_val = "text"' -i test.yaml
          yq eval '.mixed.int_val = 42' -i test.yaml
          yq eval '.mixed.float_val = 3.14' -i test.yaml
          yq eval '.mixed.bool_val = false' -i test.yaml
          yq eval '.mixed.null_val = null' -i test.yaml
          yq eval '.mixed.array_val = [1, "two", true]' -i test.yaml

          # Verify mixed types
          [[ "$(yq eval '.mixed.string_val' test.yaml)" == "text" ]] || { echo "Mixed string failed"; exit 1; }
          [[ "$(yq eval '.mixed.int_val' test.yaml)" == "42" ]] || { echo "Mixed int failed"; exit 1; }
          [[ "$(yq eval '.mixed.float_val' test.yaml)" == "3.14" ]] || { echo "Mixed float failed"; exit 1; }
          [[ "$(yq eval '.mixed.bool_val' test.yaml)" == "false" ]] || { echo "Mixed bool failed"; exit 1; }
          [[ "$(yq eval '.mixed.array_val[1]' test.yaml)" == "two" ]] || { echo "Mixed array failed"; exit 1; }

          # Test 8: YAML-specific features (arrays and objects)
          yq eval '.yaml_features.sequence = ["a", "b", "c"]' -i test.yaml
          yq eval '.yaml_features.mapping.x = 1' -i test.yaml
          yq eval '.yaml_features.mapping.y = 2' -i test.yaml
          
          # Verify YAML syntax works
          [[ "$(yq eval '.yaml_features.sequence[0]' test.yaml)" == "a" ]] || { echo "YAML sequence failed"; exit 1; }
          [[ "$(yq eval '.yaml_features.mapping.x' test.yaml)" == "1" ]] || { echo "YAML mapping failed"; exit 1; }

          # Final verification: ensure valid YAML throughout
          yq eval '.' test.yaml >/dev/null || { echo "Final YAML is invalid"; exit 1; }

          # Verify complex structure integrity
          [[ "$(yq eval '.applications.backend.database.connections.primary.credentials.username' test.yaml)" == "admin" ]] || { echo "Complex structure corrupted"; exit 1; }

          echo "YAML set operation comprehensive test passed!"
        '';
      in
      checkExecution test;
    expected = true;
  };

  # Generic Copy: Test file copying concept
  testGenericCopyExecution = {
    expr =
      let
        test = mkExecutionTest "generic-copy" ''
          # Test file copying (simulating what mkGenericActivationScript does)
          echo "=== Testing file copy operation ==="

          # Create source file
          echo "test content" > source-file

          # Simulate the script operations: mkdir -p + cat > target
          mkdir -p "$(dirname target-file)"
          cat source-file > target-file

          # Verify copy
          [[ -f "target-file" ]] || { echo "Target file not created"; exit 1; }
          content=$(cat target-file)
          [[ "$content" == "test content" ]] || { echo "Content not copied correctly: $content"; exit 1; }

          echo "File copy operation works!"
        '';
      in
      checkExecution test;
    expected = true;
  };
}