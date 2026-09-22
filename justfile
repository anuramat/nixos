export NIX_CONFIG := "extra-experimental-features = nix-command flakes pipe-operators"
rebuild := "nixos-rebuild --sudo"
keys_dir := `pwd` / "nixos-configurations" / `hostname` / "keys"

default: nixos

[private]
nixos-pre:
    # store keys in repo:
    mkdir -p "{{ keys_dir }}"
    # set locale to get deterministic ordering
    ssh-keyscan -q "$(hostname)" | LC_ALL=C sort > "{{ keys_dir }}/known_hosts"
    # find public keys and copy
    grep -rL PRIVATE "$HOME/.ssh" | grep '\.pub$' | xargs cp -ft "{{ keys_dir }}"
    # copy binary cache public key
    cp -ft "{{ keys_dir }}" "/etc/nix/cache.pem.pub" 2>/dev/null || true

[group('build')]
nixos command="switch" *flags: nixos-pre
    {{ rebuild }} {{ command }} {{ flags }}

[group('build')]
nixos-local command="switch" *flags: nixos-pre
    subs=$(nix config show substituters | tr ' ' '\n' | grep -v '^http:' | xargs) && \
    {{ rebuild }} {{ command }} --builders '' --option substituters "$subs" {{ flags }}

[group('build')]
nixos-offline command="switch" *flags: nixos-pre
    {{ rebuild }} {{ command }} --offline --builders '' {{ flags }}

[group('code')]
lint:
    statix check
    fd -F hardware-configuration.nix | xargs deadnix -l --exclude
    fd -e nix | xargs nix-instantiate --parse --quiet >/dev/null
    fd -e lua | luacheck - --codes --globals=vim -q
    fd -e sh --print0 | xargs -0 shellcheck --enable=all --color=always
    yamllint .

[group('util')]
build pkg:
    nix build ".#nixosConfigurations.$(hostname).pkgs.{{ pkg }}"

[group('util')]
run pkg *args:
    nix run ".#nixosConfigurations.$(hostname).pkgs.{{ pkg }}" -- {{ args }}

[group('util')]
update-agents:
    nix flake update claude-code claude-desktop codex chatgpt
