# anuramat/nixos

## Install

```bash
git clone --depth 1 -- git@github.com:anuramat/nixos
sudo rm -rf /etc/nixos
sudo mv -T nixos /etc/nixos
# if the machine expression is not repo yet, regenerate a hardware config:
# nixos-generate-config
make
# if the hostname doesn't match the machine:
# sudo nixos-rebuild switch --flake /etc/nixos#$YOUR_HOSTNAME
# make links
wallust theme random # some configs are generated by wallust wrapper
```

### Post

```bash
nvim # fetch plugins, install TS parsers
ssh-keygen # generate a key
gh auth login # set up github
git remote set-url origin git@github.com:anuramat/nixos # switch to ssh
sudo tailscale up "--operator=$(whoami)" # set up tailscale
# etc: spotify, web browser, telegram, proton pass
```

## Structure

- `bin:config:home` - linked to appropriate directories
- `./nix/` - flake dependencies
- `./scripts` - makefile scripts

## Problems

### Hardcoded variables

- Personal data (`nixos/user.nix`, `rg -i 'anuramat|arsen'`, maybe `.bashrc`)
- todo.sh, ~/notes
- XDG basedir spec - `rg XDGBDSV`
