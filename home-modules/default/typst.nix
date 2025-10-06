{
  xdg.dataFile =
    let
      packageName = "preamble";
      version = "1.0.0";
      rootDir = "typst/packages/local/${packageName}/${version}";
      entrypoint = "lib.typ";
    in
    {
      "${rootDir}/${entrypoint}".text = # typst
        ''
          #let conf(doc) = {
            set terms(separator: ":  ")
            doc
          }
        '';
      "${rootDir}/typst.toml".text = # toml
        ''
          [package]
          name = "${packageName}"
          version = "${version}"
          entrypoint = "${entrypoint}"
        '';
    };
}
