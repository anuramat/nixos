{ lib, ... }:
let
  toYAML = lib.generators.toYAML { };
in
{
  xdg.configFile = {
    # YAML formatter configuration
    "yamlfmt/yamlfmt.yaml".text = toYAML {
      gitignore_excludes = true;
    };

    # YAML linter configuration
    "yamllint/config".text = toYAML {
      yaml-files = [
        "*.yaml"
        "*.yml"
        ".yamllint"
      ];
      rules = {
        anchors = "enable";
        braces = "enable";
        brackets = "enable";
        colons = "enable";
        commas = "enable";
        comments.level = "warning";
        comments-indentation.level = "warning";
        document-end = "disable";
        document-start = "disable";
        empty-lines = "enable";
        empty-values = "disable";
        float-values = "disable";
        hyphens = "enable";
        indentation = "enable";
        key-duplicates = "enable";
        key-ordering = "disable";
        line-length = "disable";
        new-line-at-end-of-file = "enable";
        new-lines = "enable";
        octal-values = "disable";
        quoted-strings = "disable";
        trailing-spaces = "enable";
        truthy.level = "warning";
      };
    };
  };
}
