{ pkgs, ... }:
{
  extraPackages = with pkgs; [
    hadolint
    nodePackages.jsonlint
    vale
  ];
  plugins.lint = {
    enable = true;
    lintersByFt = {
      dockerfile = [
        "hadolint"
      ];
      json = [
        "jsonlint"
      ];
      markdown = [
        "vale"
      ];
      rst = [
        "vale"
      ];
      text = [
        "vale"
      ];
    };
  };
}
