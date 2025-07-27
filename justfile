# vim: fdm=marker fdl=0

keys_dir := `pwd` / "hosts" / `hostname` / "keys"

# Complete rebuild: format, nixos rebuild, links, lint
all: format nixos links lint

# Rebuild NixOS configuration
nixos:
    # ask for permission first
    sudo true
    # store keys in repo:
    ./scripts/heading.sh "Copying public keys"
    mkdir -p "{{keys_dir}}"
    # set locale to get deterministic ordering
    LC_ALL=C ssh-keyscan -q `hostname` | sort > "{{keys_dir}}/host_keys"
    # find public keys and copy
    grep -rL PRIVATE "$HOME/.ssh" | grep '\.pub$' | xargs cp -ft "{{keys_dir}}"
    # copy binary cache public key
    cp -ft "{{keys_dir}}" "/etc/nix/cache.pem.pub" 2>/dev/null || true
    # rebuild
    ./scripts/heading.sh "Building NixOS"
    sudo nixos-rebuild switch --option extra-experimental-features pipe-operators --show-trace

# Install symlinks from ./links directory
links:
    ./scripts/heading.sh "Setting up links"
    ./scripts/install_links.sh ./links

# Check nix files, lua files, shell scripts, yaml files
lint:
    ./scripts/heading.sh "Checking Nix files"
    echo Skipping nix linters due to lack of pipe operator support
    # statix check -i hardware-configuration.nix || true
    # deadnix || true
    ./scripts/heading.sh "Checking Lua files"
    luacheck . --codes --globals=vim -q | head -n -1
    ./scripts/heading.sh "Checking shell scripts"
    ./scripts/shrun.sh shellcheck --color=always -o all
    ./scripts/heading.sh "Checking yaml files"
    yamllint . || true

# Format all code using treefmt
format:
    ./scripts/heading.sh "Formatting"
    treefmt

# Test neovim build with expect script
nvim-expect:
    nix build ".#neovim"
    ./scripts/expect_run.sh ./result/bin/nvim