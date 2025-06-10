# vim: fdm=marker fdl=0
.SILENT:
MAKEFLAGS += --always-make

all: flake links code mcp
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
code: nix lua sh
	./scripts/heading.sh "Great success"
nvim:
	nix run --option builders '' --option substituters '' .#nvim
mcp:
	jq --slurpfile mcp ./mcp.json '.mcpServers = $$mcp[0]' ~/.claude.json | sponge ~/.claude.json


# python {{{1
python: pythonfmt
pythonfmt:
	./scripts/heading.sh "Formatting Python"
	black -q .

# nix {{{1
nix: nixfmt nixlint
nixfmt:
	./scripts/heading.sh "Formatting Nix"
	nixfmt $(shell fd -e nix)
nixlint:
	./scripts/heading.sh "Checking Nix"
	echo Skipping nix linters due to lack of pipe operator support
	# statix check -i hardware-configuration.nix || true
	# deadnix || true

# lua {{{1
lua: luafmt lualint
luafmt:
	./scripts/heading.sh "Formatting Lua"
	stylua .
lualint:
	./scripts/heading.sh "Checking Lua"
	luacheck . --codes --globals=vim -q | head -n -1

# shell {{{1
sh: shfmt shlint
shfmt:
	./scripts/heading.sh "Formatting shell"
	./scripts/shrun.sh shfmt --write --simplify --case-indent --binary-next-line --space-redirects
shlint:
	./scripts/heading.sh "Checking shell"
	./scripts/shrun.sh shellcheck --color=always -o all

# misc {{{1
misc: misclint miscfmt
misclint:
	yamllint . || true
	checkmake Makefile
miscfmt:
	yamlfmt .
