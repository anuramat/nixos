# vim: fdm=marker fdl=0

.PHONY: all flake links code
all: flake links code
flake:
	@ ./scripts/heading.sh "Building NixOS"
	@ sudo nixos-rebuild switch --option extra-experimental-features pipe-operators
links:
	@ ./scripts/heading.sh "Setting up links"
	@ BASH_ENV=/etc/profile ./scripts/install.sh
code: nix lua sh

# nix {{{1
.PHONY: nix nixlint nixfmt
nix: nixfmt nixlint
nixfmt:
	@ ./scripts/heading.sh "Formatting Nix files"
	@ nixfmt $(shell fd -e nix)
nixlint:
	@ ./scripts/heading.sh "Checking Nix files"
	@ statix check . || true
	@ deadnix || true

# lua {{{1
.PHONY: lua lualint luafmt
lua: luafmt lualint
luafmt:
	@ ./scripts/heading.sh "Formatting Lua files"
	@ stylua .
lualint:
	@ ./scripts/heading.sh "Checking Lua files"
	@ luacheck . --globals=vim | ghead -n -2

# shell {{{1
.PHONY: sh shlint shfmt
sh: shfmt shlint
shfmt:
	@ ./scripts/heading.sh "Formatting shell scripts"
	@ ./scripts/shrun.sh 'silent' 'shfmt --write --simplify --case-indent --binary-next-line --space-redirects'
shlint:
	@ ./scripts/heading.sh "Checking shell scripts"
	@ ./scripts/shrun.sh 'verbose' 'shellcheck --color=always -o all'

# # misc {{{1
# .PHONY: misc miscfmt
# miscfmt:
# 	# @ yaml
# misc:
# 	@ yamllint . || true
# TODO add make lint


keys::="nix/machines/$(shell hostname)/keys"
.PHONY: host_keys client_keys keys
host_keys:
	@ ssh-keyscan -q "$(shell hostname)" > "$(keys)/host_keys"
client_keys:
	@ grep -rL PRIVATE "$(HOME)/.ssh" | grep '\.pub$$' | xargs cp -t "$(keys)"
keys: client_keys host_keys
