# anuramat/nixos

## Install
test
- make sure the hostname matches the target

```bash
git clone --depth 1 -- git@github.com:anuramat/nixos
sudo rm -rf /etc/nixos
sudo mv -T nixos /etc/nixos
make init

nvim # fetch plugins, install TS parsers
gh auth login # github cli
git remote set-url origin git@github.com:anuramat/nixos # switch to ssh
sudo tailscale up "--operator=$(whoami)" # set up tailscale

# etc: proton pass, web browser, cache, telegram, spotify
```

## Setting up a new machine

TODO

## Problems

### Hardcoded variables

- Personal data (`nixos/user.nix`, `rg -i 'anuramat|arsen'`, maybe `.bashrc`)
- todo.sh, ~/notes
- XDG basedir spec - `rg XDGBDSV`
- wmenu books in sway config searches for files in ~/books
- `/etc/nix/cache.pem`
