# vim: fdm=marker fdl=0

.PHONY: all flake links code
all: flake links code
flake:
	@ ./scripts/heading.sh "Building NixOS"
	@ sudo nixos-rebuild switch
links:
	@ ./scripts/heading.sh "Setting up links"
	@ BASH_ENV=/etc/profile ./scripts/install.sh
code: nix lua sh

# nix {{{1
.PHONY: nix nixfmt
nixfmt:
	@ ./scripts/heading.sh "Formatting Nix files"
	@ nixfmt $(shell fd -e nix)

nix: nixfmt
	@ ./scripts/heading.sh "Checking Nix files"
	@ statix check . || true
	@ deadnix || true

# lua {{{1
.PHONY: lua luafmt
luafmt:
	@ ./scripts/heading.sh "Formatting Lua files"
	@ stylua .
lua: luafmt
	@ ./scripts/heading.sh "Checking Lua files"
	@ luacheck . --globals=vim | ghead -n -2

# shell {{{1
.PHONY: sh shfmt
shfmt:
	@ ./scripts/heading.sh "Formatting shell scripts"
	@ ./scripts/shrun.sh 'silent' 'shfmt --write --simplify --case-indent --binary-next-line --space-redirects'
sh: shfmt
	@ ./scripts/heading.sh "Checking shell scripts"
	@ ./scripts/shrun.sh 'verbose' 'shellcheck --color=always -o all'

# misc {{{1
.PHONY: misc miscfmt
miscfmt:
	# @ yaml
misc:
	@ yamllint . || true
