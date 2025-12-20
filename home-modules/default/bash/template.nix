{
  pkgs,
  ...
}:
let
  template = pkgs.writeShellApplication {
    name = "template";
    text = # bash
      ''
        set +u
        main() (
          local root="$HOME/notes/templates"
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

in

{
  home.packages = [
    template
  ];
}
