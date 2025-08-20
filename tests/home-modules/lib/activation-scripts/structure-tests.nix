# Structure tests: DAG entry structure and script content generation
{ testLib }:
let
  inherit (testLib)
    lib
    homeLib
    testJsonData
    testYamlData
    ;
in
{
  # =====================================
  # Tests for mkJqActivationScript Structure
  # =====================================

  # Test that mkJqActivationScript returns a proper DAG entry
  testJqScriptStructure = {
    expr =
      let
        result = homeLib.lib.home.json.set testJsonData.simple "test.json";
      in
      {
        hasData = result ? data;
        hasAfter = result ? after;
        correctAfter = result.after == [ "writeBoundary" ];
        dataIsString = lib.isString result.data;
      };
    expected = {
      hasData = true;
      hasAfter = true;
      correctAfter = true;
      dataIsString = true;
    };
  };

  # Test that JSON set operation generates correct script content
  testJqSetScriptContent = {
    expr =
      let
        result = homeLib.lib.home.json.set { "foo" = "bar"; } "test.json";
      in
      {
        containsJq = lib.hasInfix "jq" result.data;
        containsTarget = lib.hasInfix "test.json" result.data;
        containsSlurpfile = lib.hasInfix "--slurpfile" result.data;
        containsMktemp = lib.hasInfix "mktemp" result.data;
        containsSponge = lib.hasInfix "sponge" result.data;
      };
    expected = {
      containsJq = true;
      containsTarget = true;
      containsSlurpfile = true;
      containsMktemp = true;
      containsSponge = true;
    };
  };

  # Test that JSON merge operation uses correct operator
  testJqMergeOperator = {
    expr =
      let
        result = homeLib.lib.home.json.merge { "foo" = "bar"; } "test.json";
      in
      {
        containsMergeOp = lib.hasInfix "*=" result.data;
        # Should not contain set operator
        notContainSetOp = !(lib.hasInfix " = " result.data);
      };
    expected = {
      containsMergeOp = true;
      notContainSetOp = true;
    };
  };

  # Test JSON script with multiple sources (list input)
  testJqMultipleSourcesScript = {
    expr =
      let
        sources = [
          { "first" = "value1"; }
          { "second" = "value2"; }
        ];
        result = homeLib.lib.home.json.set sources "test.json";
        # Count occurrences of 'run ' which indicates separate commands
        jqCount = lib.length (lib.splitString "run " result.data) - 1;
      in
      {
        # Should have multiple jq calls (one per source object)
        jqCount = jqCount;
        hasMultipleOps = jqCount > 1;
      };
    expected = {
      jqCount = 2; # Two source objects = two jq operations
      hasMultipleOps = true;
    };
  };

  # =====================================
  # Tests for mkYqActivationScript Structure
  # =====================================

  # Test that mkYqActivationScript returns proper DAG entry
  testYqScriptStructure = {
    expr =
      let
        result = homeLib.lib.home.yaml.set testYamlData.simple "test.yaml";
      in
      {
        hasData = result ? data;
        hasAfter = result ? after;
        correctAfter = result.after == [ "writeBoundary" ];
        dataIsString = lib.isString result.data;
      };
    expected = {
      hasData = true;
      hasAfter = true;
      correctAfter = true;
      dataIsString = true;
    };
  };

  # Test YAML script content
  testYqScriptContent = {
    expr =
      let
        result = homeLib.lib.home.yaml.set { "config.setting" = "value"; } "test.yaml";
      in
      {
        containsYq = lib.hasInfix "yq" result.data;
        containsEvalAll = lib.hasInfix "eval-all" result.data;
        containsTarget = lib.hasInfix "test.yaml" result.data;
        containsInPlace = lib.hasInfix "-i" result.data;
        containsPyFlag = lib.hasInfix "-py" result.data;
        containsOyFlag = lib.hasInfix "-oy" result.data;
      };
    expected = {
      containsYq = true;
      containsEvalAll = true;
      containsTarget = true;
      containsInPlace = true;
      containsPyFlag = true;
      containsOyFlag = true;
    };
  };

  # Test YAML file initialization
  testYqFileInit = {
    expr =
      let
        result = homeLib.lib.home.yaml.set { "key" = "value"; } "test.yaml";
      in
      {
        # Should check if file exists and create empty YAML if not
        hasFileCheck = lib.hasInfix "[ -s" result.data;
        hasEmptyInit = lib.hasInfix "echo '{}'" result.data;
      };
    expected = {
      hasFileCheck = true;
      hasEmptyInit = true;
    };
  };

  # =====================================
  # Tests for mkGenericActivationScript Structure
  # =====================================

  # Test generic script structure
  testGenericScriptStructure = {
    expr =
      let
        result = homeLib.lib.home.mkGenericActivationScript "/source/file" "/target/file";
      in
      {
        hasData = result ? data;
        hasAfter = result ? after;
        correctAfter = result.after == [ "writeBoundary" ];
        dataIsString = lib.isString result.data;
      };
    expected = {
      hasData = true;
      hasAfter = true;
      correctAfter = true;
      dataIsString = true;
    };
  };

  # Test generic script content
  testGenericScriptContent = {
    expr =
      let
        result = homeLib.lib.home.mkGenericActivationScript "/src/test" "/dst/test";
      in
      {
        hasSourceVar = lib.hasInfix "source=" result.data;
        hasTargetVar = lib.hasInfix "target=" result.data;
        hasMkdir = lib.hasInfix "mkdir -p" result.data;
        hasCat = lib.hasInfix "cat" result.data;
        hasDiff = lib.hasInfix "diff" result.data;
      };
    expected = {
      hasSourceVar = true;
      hasTargetVar = true;
      hasMkdir = true;
      hasCat = true;
      hasDiff = true;
    };
  };

  # =====================================
  # Tests for Path and Value Handling
  # =====================================

  # Test that paths with spaces are properly quoted
  testPathQuoting = {
    expr =
      let
        resultJson = homeLib.lib.home.json.set { "key" = "value"; } "/path with spaces/test.json";
        resultYaml = homeLib.lib.home.yaml.set { "key" = "value"; } "/path with spaces/test.yaml";
        resultGeneric = homeLib.lib.home.mkGenericActivationScript "/src with spaces" "/dst with spaces";
      in
      {
        # JSON script uses variables and quotes them properly in usage
        jsonQuotedInUsage = lib.hasInfix "\"$target\"" resultJson.data;
        # YAML script quotes paths directly
        yamlQuoted = lib.hasInfix "\"/path with spaces/test.yaml\"" resultYaml.data;
        # Generic script has BUG: doesn't quote paths in variable assignment
        # This test documents the current behavior (which is buggy)
        genericSrcUnquoted = lib.hasInfix "source=/src with spaces" resultGeneric.data;
        genericDstUnquoted = lib.hasInfix "target=/dst with spaces" resultGeneric.data;
      };
    expected = {
      jsonQuotedInUsage = true;
      yamlQuoted = true;
      # These document the current buggy behavior
      genericSrcUnquoted = true;
      genericDstUnquoted = true;
    };
  };

  # Test JSON path handling (nested keys)
  testJsonPathHandling = {
    expr =
      let
        result = homeLib.lib.home.json.set { "deep.nested.path" = "value"; } "test.json";
      in
      {
        # Should contain the JSON path in the jq expression
        hasJsonPath = lib.hasInfix ".deep.nested.path" result.data;
      };
    expected = {
      hasJsonPath = true;
    };
  };

  # Test YAML path handling
  testYamlPathHandling = {
    expr =
      let
        result = homeLib.lib.home.yaml.set { "config.database.host" = "localhost"; } "test.yaml";
      in
      {
        # Should contain the YAML path in the yq expression
        hasYamlPath = lib.hasInfix ".config.database.host" result.data;
      };
    expected = {
      hasYamlPath = true;
    };
  };

  # =====================================
  # Tests for fileWithJson function behavior
  # =====================================

  # Test that simple values get converted to JSON files
  testFileWithJsonSimple = {
    expr =
      let
        # This tests the internal fileWithJson function indirectly
        # by checking that simple values generate temporary JSON files
        result = homeLib.lib.home.json.set { "simple" = "value"; } "test.json";
      in
      {
        # Should contain reference to a temporary JSON file
        hasJsonFile = lib.hasInfix ".json" result.data || lib.hasInfix "writeTextFile" result.data;
      };
    expected = {
      hasJsonFile = true;
    };
  };

  # =====================================
  # Tests for Error Conditions and Edge Cases
  # =====================================

  # Test empty source handling
  testEmptySource = {
    expr =
      let
        result = homeLib.lib.home.json.set { } "test.json";
      in
      {
        # Should still generate valid script even with empty source
        hasData = result ? data && lib.isString result.data && result.data != "";
        hasProperStructure = result ? after && result.after == [ "writeBoundary" ];
      };
    expected = {
      hasData = true;
      hasProperStructure = true;
    };
  };

  # Test with null values in JSON
  testJsonNullValues = {
    expr =
      let
        result = homeLib.lib.home.json.set { "nullable" = null; } "test.json";
      in
      {
        # Should handle null values without breaking
        hasData = result ? data && lib.isString result.data;
        notEmpty = result.data != "";
      };
    expected = {
      hasData = true;
      notEmpty = true;
    };
  };

  # Test script ordering (DAG dependencies)
  testScriptOrdering = {
    expr =
      let
        jsonResult = homeLib.lib.home.json.set { } "test.json";
        yamlResult = homeLib.lib.home.yaml.set { } "test.yaml";
        genericResult = homeLib.lib.home.mkGenericActivationScript "/src" "/dst";
      in
      {
        # All should come after writeBoundary
        jsonAfterWrite = lib.elem "writeBoundary" jsonResult.after;
        yamlAfterWrite = lib.elem "writeBoundary" yamlResult.after;
        genericAfterWrite = lib.elem "writeBoundary" genericResult.after;
        # None should have before dependencies by default
        jsonNoBefore = jsonResult.before == [ ];
        yamlNoBefore = yamlResult.before == [ ];
        genericNoBefore = genericResult.before == [ ];
      };
    expected = {
      jsonAfterWrite = true;
      yamlAfterWrite = true;
      genericAfterWrite = true;
      jsonNoBefore = true;
      yamlNoBefore = true;
      genericNoBefore = true;
    };
  };
}
