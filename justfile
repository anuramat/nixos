keys_dir := `pwd` / "hosts" / `hostname` / "keys"

all: flake format (test "--quiet") lint nixos

[group('build')]
nixos:
    # ask for permission first
    sudo true
    # store keys in repo:
    mkdir -p "{{ keys_dir }}"
    # set locale to get deterministic ordering
    ssh-keyscan -q "$(hostname)" | LC_ALL=C sort > "{{ keys_dir }}/host_keys"
    # find public keys and copy
    grep -rL PRIVATE "$HOME/.ssh" | grep '\.pub$' | xargs cp -ft "{{ keys_dir }}"
    # copy binary cache public key
    cp -ft "{{ keys_dir }}" "/etc/nix/cache.pem.pub" 2>/dev/null || true
    # rebuild
    sudo nixos-rebuild switch --option extra-experimental-features pipe-operators --show-trace

[group('code')]
test flag="" arch=`nix eval --raw .#nixosConfigurations.$(hostname).config.nixpkgs.hostPlatform.system`:
    nix-unit {{ flag }} --flake .#tests.systems.{{ arch }}

[group('code')]
lint:
    # Skipping nix linters due to lack of pipe operator support:
    # statix check -i hardware-configuration.nix || true
    # deadnix || true
    fd -e lua | luacheck - --codes --globals=vim -q
    fd -e sh --print0 | xargs -0 shellcheck --enable=all --color=always
    yamllint .

[group('code')]
format:
    treefmt

[group('util')]
build pkg:
    nix build ".#nixosConfigurations.$(hostname).pkgs.{{ pkg }}"

[group('util')]
run pkg:
    nix run ".#nixosConfigurations.$(hostname).pkgs.{{ pkg }}"

# Regenerate flake
flake:
    # Check if it evaluates first
    nix eval --read-only --expr "$(nix eval -f inputs.nix)" >/dev/null
    # Regenerate flake.nix
    printf '{ outputs = args: import ./outputs.nix args; inputs = %s; }' "$(nix eval --read-only -f inputs.nix)" > flake.nix
    # Format
    treefmt flake.nix

# Install pre-commit hooks
[group('util')]
hooks:
    # TODO format
    # TODO `just flake`

# Check a NixOS configuration
[group('check')]
check-nixos host=`hostname`: (check ".#nixosConfigurations." + host + ".config.system.build.toplevel")

# Check a Home Manager configuration
[group('check')]
check-hm user=`whoami`: (check ".#homeConfigurations." + user + ".activationPackage")

[group('check')]
check target="":
    {{ if target == "" { "nix flake check" } else { "nix build " + target + " --show-trace --no-link --dry-run" } }}
    # another option: nix eval "{{ target }}.drvPath"

# Run all checks and tests
[group('check')]
check-all *flags:
    nix flake check {{ flags }}
    # add --no-build to skip checks and only check outputs
    # also --all-systems
