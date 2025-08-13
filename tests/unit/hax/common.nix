{ pkgs, lib }:
let
  hax = import ../../../hax/common.nix { inherit lib; };

  # Mock file for readLines test
  mockFile = pkgs.writeText "lines.txt" ''
    line1
    line2

    line3
  '';
in
{
  fileOperations = {
    readLines = {
      expr = hax.readLines mockFile;
      expected = [
        "line1"
        "line2"
        "line3"
      ];
    };

    readLinesEmpty = {
      expr = hax.readLines (pkgs.writeText "empty.txt" "");
      expected = [ ];
    };

    join = {
      expr = hax.join ''
        line1
        line2
        line3
      '';
      expected = "line1 line2 line3 ";
    };

    joinSingle = {
      expr = hax.join "single";
      expected = "single";
    };
  };

  schemaAndTypeMatching = {
    getSchema = {
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

    getSchemaEmpty = {
      expr = hax.getSchema { };
      expected = { };
    };

    getMatchesExact = {
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

    getMatchesSet = {
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

    getMatchesList = {
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
  };

  pythonConfig = {
    simple = {
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

    nested = {
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

    deep = {
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

    mixed = {
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

    empty = {
      expr = hax.pythonConfig "empty" { };
      expected = "";
    };
  };
}
