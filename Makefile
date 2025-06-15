# vim: fdm=marker fdl=0
.SILENT:
MAKEFLAGS += --always-make

all: flake links mcp lint
flake:
	sudo true
	./scripts/heading.sh "Copying public keys"
	mkdir -p "$(keys_dir)"
	LC_ALL=C ssh-keyscan -q "$(shell hostname)" | sort > "$(keys_dir)/host_keys"
	grep -rL PRIVATE "$(HOME)/.ssh" | grep '\.pub$$' | xargs cp -ft "$(keys_dir)"
	cp -ft "$(keys_dir)" "/etc/nix/cache.pem.pub" 2>/dev/null || true
	./scripts/heading.sh "Building NixOS"
	sudo nixos-rebuild switch --option extra-experimental-features pipe-operators --show-trace
	./scripts/heading.sh "Great success"
links:
	./scripts/heading.sh "Setting up links"
	./scripts/install.sh ./links
	./scripts/heading.sh "Great success"
machine_dir::=$(shell pwd)/os/machines/$(shell hostname)
keys_dir::=$(machine_dir)/keys
init:
	./scripts/heading.sh "Initial install"
	./scripts/guard.sh
	./scripts/heading.sh "Generating keys"
	./scripts/keygen.sh
	./scripts/heading.sh "Great success"
claude:
	jq --slurpfile mcp ./mcp.json '.mcpServers = $$mcp[0]' ~/.claude.json | sponge ~/.claude.json
	jq '.projects |= map (. + {hasClaudeMdExternalIncludesApproved:true})' ~/.claude.json | sponge ~/.claude.json

nvim:
	nix run --option builders '' --option substituters '' .#neovim

lint:
	./scripts/heading.sh "Checking Nix"
	echo Skipping nix linters due to lack of pipe operator support
	# statix check -i hardware-configuration.nix || true
	# deadnix || true
	./scripts/heading.sh "Checking Lua"
	luacheck . --codes --globals=vim -q | head -n -1
	./scripts/heading.sh "Checking shell"
	./scripts/shrun.sh shellcheck --color=always -o all
	./scripts/heading.sh "Yaml"
	yamllint . || true
	checkmake Makefile
