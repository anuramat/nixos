# anuramat/nixos

![TODO](https://img.shields.io/github/search?query=repo%3Aanuramat%2Fnixos%20TODO&style=flat-square&logo=nixos&color=blue&labelColor=black&label=TODO&link=&link=https%3A%2F%2Fgithub.com%2Fsearch%3Fq%3Drepo%253Aanuramat%252Fnixos%2520TODO%26type%3Dcode)
![BUG](https://img.shields.io/github/search?query=repo%3Aanuramat%2Fnixos%20BUG&style=flat-square&logo=gnubash&color=purple&labelColor=black&label=BUG&link=&link=https%3A%2F%2Fgithub.com%2Fsearch%3Fq%3Drepo%253Aanuramat%252Fnixos%2520BUG%26type%3Dcode)
![FUCK](https://img.shields.io/github/search?query=repo%3Aanuramat%2Fnixos%20FUCK&style=flat-square&logo=cplusplus&color=red&labelColor=black&label=FUCK&link=&link=https%3A%2F%2Fgithub.com%2Fsearch%3Fq%3Drepo%253Aanuramat%252Fnixos%2520FUCK%26type%3Dcode)

## Install

0. prepare `nixos-configurations/$HOSTNAME/default.nix`
1. install the base (reminder: swap and luks)
2. connect with `nmtui`
3. install the config:


```bash
# backup
cp -r /etc/nixos ~/old

# get the repo
nix-shell -p git
git clone --depth 1 https://github.com/anuramat/nixos ~/nixos
sudo rm -rf /etc/nixos
sudo mv -T ~/nixos /etc/nixos

# add hw config
cp "$HOME/old/hardware-configuration.nix" "/etc/nixos/nixos-configurations/$HOSTNAME"
git -C /etc/nixos add -A

# install
export NIX_CONFIG="experimental-features = nix-command flakes pipe-operators"
nix develop
# TODO put these into the justfile, together with some other bootstrap stuff
nh os switch /etc/nixos -H "$HOSTNAME"
# might fail; try
sudo nixos-rebuild switch --option extra-experimental-features pipe-operators --flake ".#$HOSTNAME"
```

todo:

```bash
# - keygen script -- make easily accessible from dev shell
# - new step: unfuck the repo (switch to ssh and unshallow)
```

some extras:

```bash
nix-cache-keygen # only if this machine is a builder XXX am I sure about this? seems like we need it regardless
# misc
gh auth login
# TODO upload ssh key to github; might be doable with gh auth
sudo tailscale up "--operator=$(whoami)"
# TODO protonmail bridge
```

## Problems

- sshKey and sshUser in nix.buildMachines are ignored: <https://github.com/NixOS/nix/issues/3423>;
  for now add this to /root/.ssh/config:
  ```ssh_config
  Host anuramat-ll7
          IdentitiesOnly yes
          IdentityFile /home/anuramat/.ssh/id_ed25519
          User builder
          ConnectTimeout 3
  ```
