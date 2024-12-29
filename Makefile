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
.PHONY: nix nixlint nixfmt
nixfmt:
	@ ./scripts/heading.sh "Formatting Nix files"
	@ nixfmt $(shell fd -e nix)
nixlint:
	@ ./scripts/heading.sh "Checking Nix files"
	@ statix check . || true
	@ deadnix || true
nix: nixfmt nixlint

# lua {{{1
.PHONY: lua lualint luafmt
luafmt:
	@ ./scripts/heading.sh "Formatting Lua files"
	@ stylua .
lualint:
	@ ./scripts/heading.sh "Checking Lua files"
	@ luacheck . --globals=vim | ghead -n -2
lua: luafmt lualint

# shell {{{1
.PHONY: sh shlint shfmt
shfmt:
	@ ./scripts/heading.sh "Formatting shell scripts"
	@ ./scripts/shrun.sh 'silent' 'shfmt --write --simplify --case-indent --binary-next-line --space-redirects'
shlint:
	@ ./scripts/heading.sh "Checking shell scripts"
	@ ./scripts/shrun.sh 'verbose' 'shellcheck --color=always -o all'
sh: shfmt shlint

# # misc {{{1
# .PHONY: misc miscfmt
# miscfmt:
# 	# @ yaml
# misc:
# 	@ yamllint . || true
