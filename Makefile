# vim: fdm=marker fdl=0
.SILENT:
.PHONY: clean test

.PHONY: all flake links code dupe init_pre init
all: flake links code
flake: dupe
	./scripts/heading.sh "Building NixOS"
	if command -v nh &>/dev/null; then nh os switch .; else sudo nixos-rebuild switch --option extra-experimental-features pipe-operators; fi
links:
	./scripts/heading.sh "Setting up links"
	BASH_ENV=/etc/profile ./scripts/install.sh
machine_dir::=$(shell pwd)/nix/machines/$(shell hostname)
keys_dir::=$(machine_dir)/keys
dupe:
	./scripts/heading.sh "Copying public keys"
	mkdir -p "$(keys_dir)"
	LC_ALL=C ssh-keyscan -q "$(shell hostname)" | sort > "$(keys_dir)/host_keys"
	grep -rL PRIVATE "$(HOME)/.ssh" | grep '\.pub$$' | xargs cp -ft "$(keys_dir)"
	cp -ft "$(keys_dir)" "/etc/nix/cache.pem.pub" 2>/dev/null || true
init_pre:
	./scripts/heading.sh "Initial install"
	./scripts/guard.sh
	./scripts/heading.sh "Generating hardware configuration"
	nixos-generate-config --show-hardware-config > "$(machine_dir)"/hardware-configuration.nix
	./scripts/heading.sh "Generating keys"
	./scripts/keygen.sh
# if only there was a better way... too bad order-only prerequisites are not order-only
init: init_pre .WAIT all
	./scripts/heading.sh "Applying a theme"
	source ./config/bash/config.d/01-wallust.sh && __wallust_wrapped theme random
code: nix lua sh

# nix {{{1
.PHONY: nix nixlint nixfmt
nix: nixfmt nixlint
nixfmt:
	./scripts/heading.sh "Formatting Nix files"
	nixfmt $(shell fd -e nix)
nixlint:
	./scripts/heading.sh "Checking Nix files"
	echo Skipping nix linters due to lack of pipe operator support
	# statix check -i hardware-configuration.nix || true
	# deadnix || true

# lua {{{1
.PHONY: lua lualint luafmt
lua: luafmt lualint
luafmt:
	./scripts/heading.sh "Formatting Lua files"
	stylua .
lualint:
	./scripts/heading.sh "Checking Lua files"
	luacheck . --codes --globals=vim -q | head -n -1

# shell {{{1
.PHONY: sh shlint shfmt
sh: shfmt shlint
shfmt:
	./scripts/heading.sh "Formatting shell scripts"
	./scripts/shrun.sh shfmt --write --simplify --case-indent --binary-next-line --space-redirects
shlint:
	./scripts/heading.sh "Checking shell scripts"
	./scripts/shrun.sh shellcheck --color=always -o all

# misc {{{1
.PHONY: misc misclint miscfmt
misc: misclint miscfmt
misclint:
	yamllint . || true
	checkmake Makefile
miscfmt:
	yamlfmt .
