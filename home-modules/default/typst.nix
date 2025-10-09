# TODO try removing tmpdir
{
  pkgs,
  ...
}:
let
  # minimal valid pdf file, base64 encoded
  # TODO maybe put to a file in nix store
  pdfPlaceholder = "JVBERi0xLgoxIDAgb2JqPDwvUGFnZXMgMiAwIFI+PmVuZG9iagoyIDAgb2JqPDwvS2lkc1szIDAgUl0vQ291bnQgMT4+ZW5kb2JqCjMgMCBvYmo8PC9QYXJlbnQgMiAwIFI+PmVuZG9iagp0cmFpbGVyIDw8L1Jvb3QgMSAwIFI+Pg==";
  hotdoc = pkgs.writeShellApplication {
    name = "hotdoc";
    runtimeInputs = with pkgs; [
      typst
      zathura
    ];
    text =
      # bash
      ''
        typ=$(realpath "$1")
        shift
        pdf="$(mktemp --tmpdir "$(basename -s .typ "$typ")-XXXXXXXX.pdf")"
        echo '${pdfPlaceholder}' | base64 -d >"$pdf"
        nohup zathura "$pdf" &>/dev/null &
        # zathura_pid="$!"
        disown
        typst watch "$@" "$typ" "$pdf"
        # TODO close zathura on ctrl-c somehow
      '';
  };
in
{
  home.packages = [
    hotdoc
  ];
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
