{ pkgs, lib }:
let
  hax = import ../../hax/common.nix { inherit lib; };

  # Mock file for readLines test
  mockFile = pkgs.writeText "lines.txt" ''
    line1
    line2

    line3
  '';
in
{
  # Test readLines
  testReadLines = {
    expr = hax.readLines mockFile;
    expected = [
      "line1"
      "line2"
      "line3"
    ];
  };

  # Test readLines with empty file
  testReadLinesEmpty = {
    expr = hax.readLines (pkgs.writeText "empty.txt" "");
    expected = [ ];
  };

  # Test getSchema
  testGetSchema = {
    expr = hax.getSchema {
      str = "hello";
      num = 42;
      bool = true;
      nested = {
        list = [
          1
          2
          3
        ];
        inner = {
          path = /tmp/test;
        };
      };
    };
    expected = {
      str = "string";
      num = "int";
      bool = "bool";
      nested = {
        list = "list";
        inner = {
          path = "path";
        };
      };
    };
  };

  # Test join
  testJoin = {
    expr = hax.join ''
      line1
      line2
      line3
    '';
    expected = "line1 line2 line3 ";
  };

  # Test join with single line
  testJoinSingle = {
    expr = hax.join "single";
    expected = "single";
  };

  # Test getMatches with exact type match
  testGetMatchesExact = {
    expr = hax.getMatches {
      str = "string";
      num = "int";
      list = "list";
    } "hello";
    expected = {
      str = true;
      num = false;
      list = false;
    };
  };

  # Test getMatches with set type (schema comparison)
  testGetMatchesSet = {
    expr =
      hax.getMatches
        {
          simple = {
            a = "string";
            b = "int";
          };
          complex = {
            x = {
              y = "bool";
            };
          };
          wrong = {
            foo = "string";
          };
        }
        {
          a = "test";
          b = 123;
        };
    expected = {
      simple = true;
      complex = false;
      wrong = false;
    };
  };

  # Test pythonConfig simple
  testPythonConfigSimple = {
    expr = hax.pythonConfig "app" {
      debug = true;
      port = 8080;
      host = "localhost";
    };
    expected = ''
      app.debug = True
      app.host = "localhost"
      app.port = 8080'';
  };

  # Test pythonConfig with nested attributes
  testPythonConfigNested = {
    expr = hax.pythonConfig "config" {
      database = {
        host = "db.example.com";
        port = 5432;
        ssl = false;
      };
      cache = {
        enabled = true;
        ttl = 3600;
      };
    };
    expected = ''
      config.cache.enabled = True
      config.cache.ttl = 3600
      config.database.host = "db.example.com"
      config.database.port = 5432
      config.database.ssl = False'';
  };

  # Test pythonConfig with deeply nested
  testPythonConfigDeep = {
    expr = hax.pythonConfig "settings" {
      api = {
        v1 = {
          endpoints = {
            timeout = 30;
            retries = 3;
          };
        };
      };
    };
    expected = ''
      settings.api.v1.endpoints.retries = 3
      settings.api.v1.endpoints.timeout = 30'';
  };

  # Test pythonConfig with mixed types
  testPythonConfigMixed = {
    expr = hax.pythonConfig "test" {
      string = "value";
      number = 42;
      float = 3.14;
      bool_true = true;
      bool_false = false;
    };
    expected = ''
      test.bool_false = False
      test.bool_true = True
      test.float = 3.140000
      test.number = 42
      test.string = "value"'';
  };

  # Test pythonConfig empty
  testPythonConfigEmpty = {
    expr = hax.pythonConfig "empty" { };
    expected = "";
  };

  # Test getSchema with empty attrs
  testGetSchemaEmpty = {
    expr = hax.getSchema { };
    expected = { };
  };

  # Test getMatches with list type
  testGetMatchesList = {
    expr =
      hax.getMatches
        {
          array = "list";
          object = "set";
        }
        [
          1
          2
          3
        ];
    expected = {
      array = true;
      object = false;
    };
  };
}
