{
  pkgs,
  config,
  ...
}:

let

  root = "${config.home.homeDirectory}/notes/templates";

  completion =
    pkgs.writeText "template-completion.sh"
      # bash
      ''
        _template() {
          local cur root
          root="${root}"

          # only first argument and if root exists
          if ((COMP_CWORD != 1)) || [ ! -d "$root" ]; then
            COMPREPLY=()
            return 0
          fi

          local -a candidates
          mapfile -d "" -t candidates < <(
            find "$root" -maxdepth 1 -mindepth 1 -type d -printf '%f\0' 2>/dev/null
          )

          COMPREPLY=($(compgen -W "''${candidates[*]}" -- "''${COMP_WORDS[COMP_CWORD]}"))
        }
        complete -F _template template
      '';

  binpkg = pkgs.writeShellApplication {
    name = "template";
    text = # bash
      ''
        set +u
        main() (
          local root="${root}"
          if [ -z "$1" ]; then
            ls "$root"
            return
          fi
          local path="$root/$1"
          [ -d "$path" ] || {
            echo "$path is not a directory"
          }
          shopt -s dotglob
          cp "$path"/* ./
        )
        main "$@"
      '';
  };

  pkg = binpkg.overrideAttrs (old: {
    buildCommand =
      old.buildCommand
      + "install -Dm644 ${completion} $out/share/bash-completion/completions/template.bash";
  });

in

{
  home.packages = [
    pkg
  ];
}
