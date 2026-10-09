# standalone home manager

Write `home-configurations/$NAME.nix` (or
`home-configurations/$NAME/default.nix`), modeled on
`home-configurations/anuramat-linux.nix` / `anuramat-darwin.nix`: import
`standalone` plus the layers for that platform, and take `username` from
`inputs.self.consts.user`. Then add `$NAME = "$SYSTEM";` to `homeSystems` in
`outputs.nix`; that entry also creates `checks.$SYSTEM.home-$NAME`.
