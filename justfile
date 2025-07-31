keys_dir := `pwd` / "hosts" / `hostname` / "keys"

all: format lint nixos

# Rebuild
nixos:
    # ask for permission first
    sudo true
    # store keys in repo:
    mkdir -p "{{keys_dir}}"
    # set locale to get deterministic ordering
    ssh-keyscan -q "$(hostname)" | LC_ALL=C sort > "{{keys_dir}}/host_keys"
    # find public keys and copy
    grep -rL PRIVATE "$HOME/.ssh" | grep '\.pub$' | xargs cp -ft "{{keys_dir}}"
    # copy binary cache public key
    cp -ft "{{keys_dir}}" "/etc/nix/cache.pem.pub" 2>/dev/null || true
    # rebuild
    sudo nixos-rebuild switch --option extra-experimental-features pipe-operators --show-trace

# Lint nix, sh, lua, yaml
lint:
    # Skipping nix linters due to lack of pipe operator support:
    # statix check -i hardware-configuration.nix || true
    # deadnix || true
    luacheck . --codes --globals=vim -q
    fd -e sh --print0 | xargs -0 shellcheck --enable=all --color=always
    yamllint .

format:
    treefmt

# Test neovim build with expect script (probably broken)
nvim-expect:
    nix build ".#neovim"
    ./scripts/expect_run.sh ./result/bin/nvim

build pkg:
  nix build ".#nixosConfigurations.$(hostname).pkgs.{{pkg}}"

run pkg:
  nix run ".#nixosConfigurations.$(hostname).pkgs.{{pkg}}"

# Update flake inputs
inputs:
  printf '{ outputs = args: import ./outputs.nix args; inputs = %s; }' "$(nix eval -f inputs.nix)" > flake.nix
  treefmt -f nix
