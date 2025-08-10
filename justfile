keys_dir := `pwd` / "hosts" / `hostname` / "keys"

all: format lint nixos

# Rebuild
nixos: flake
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
    fd -e lua | luacheck - --codes --globals=vim -q
    fd -e sh --print0 | xargs -0 shellcheck --enable=all --color=always
    yamllint .

format:
    treefmt

build pkg:
  nix build ".#nixosConfigurations.$(hostname).pkgs.{{pkg}}"

run pkg:
  nix run ".#nixosConfigurations.$(hostname).pkgs.{{pkg}}"

# Regenerate flake
flake:
  # Check if it evaluates
  nix eval --read-only --expr "$(nix eval -f inputs.nix)" >/dev/null
  printf '{ outputs = args: import ./outputs.nix args; inputs = %s; }' "$(nix eval --read-only -f inputs.nix)" > flake.nix
  treefmt flake.nix

# Install pre-commit hooks
hooks:
  # TODO format
  # TODO just inputs

check-nixos host="anuramat-ll7":
  nix build ".#nixosConfigurations.{{host}}.config.system.build.toplevel"

check-hm:
  nix build .#homeConfigurations.anuramat.activationPackage
