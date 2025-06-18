# vim: fdm=marker fdl=0
.SILENT:
MAKEFLAGS += --always-make

keys_dir::=$(shell pwd)/hosts/$(shell hostname)/keys

all: format flake links claude lint
flake:
	sudo true
	./scripts/heading.sh "Copying public keys"
	mkdir -p "$(keys_dir)"
	LC_ALL=C ssh-keyscan -q "$(shell hostname)" | sort > "$(keys_dir)/host_keys"
	grep -rL PRIVATE "$(HOME)/.ssh" | grep '\.pub$$' | xargs cp -ft "$(keys_dir)"
	cp -ft "$(keys_dir)" "/etc/nix/cache.pem.pub" 2>/dev/null || true
	./scripts/heading.sh "Building NixOS"
	sudo nixos-rebuild switch --option extra-experimental-features pipe-operators --show-trace
links:
	./scripts/heading.sh "Setting up links"
	./scripts/install_links.sh ./links
claude:
	./scripts/mcp.sh

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
	./scripts/heading.sh "Checking Makefile"
	checkmake Makefile
format:
	./scripts/heading.sh "Formatting"
	treefmt
nvim-expect:
	nix build ".#neovim"
	./scripts/expect_run.sh ./result/bin/nvim
