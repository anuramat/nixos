# standalone home manager

write to `home-configurations/$CONFIG_NAME.nix` or
`home-configurations/$CONFIG_NAME/default.nix`, then add an entry to the builder
in `outputs.nix`

```nix
{ inputs, ... }:
{
  imports = with inputs.self.homeModules; [
    default
    heavy
    anuramat
    standalone
    darwin
  ];
  home =
    let
      username = "anuramat";
    in
    {
      inherit username;
      stateVersion = "25.05";
      homeDirectory = "/Users/${username}";
    };
}
```
