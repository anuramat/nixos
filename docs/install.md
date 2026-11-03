# Install

The new host (`$H` below) is installed from a machine that already runs this
config (the "build machine", ideally on the same network): it builds the whole
system and pushes it into the installer, so the new host never builds anything.

## 1. Installer ISO (build machine)

Minimal installer (already has NetworkManager) with sshd running, the build
machine's ssh key authorized for root, and the experimental features this
flake needs:

```bash
cd /etc/nixos
B=$(hostname) # whose ssh keys may log into the installer
nix build --builders '' --impure --expr "
let
  self = builtins.getFlake \"/etc/nixos\";
  nixpkgs = self.inputs.nixpkgs;
in
(nixpkgs.lib.nixosSystem {
  modules = [
    \"\${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix\"
    ({ lib, ... }: {
      nixpkgs.hostPlatform = \"x86_64-linux\";
      nix.settings.experimental-features = \"nix-command flakes pipe-operators\";
      systemd.services.sshd.wantedBy = lib.mkForce [ \"multi-user.target\" ];
      users.users.root.openssh.authorizedKeys.keys = self.keys.$B.clientKeys;
    })
  ];
}).config.system.build.isoImage"
lsblk # find the USB stick
sudo dd if=$(echo result/iso/*.iso) of=/dev/sdX bs=4M status=progress oflag=sync
```

`--builders ''` keeps the build local: it's mostly substituted from
cache.nixos.org, and offloading it to a builder means downloading the ~1GB
image back.

## 2. Partitioning (installer)

Connect with `nmtui`, then partition (LUKS root; no swap partition -- use
`swapDevices` with a swap file in the host config):

```bash
lsblk
D=/dev/nvme0n1
parted -s $D -- mklabel gpt mkpart ESP fat32 1MiB 1GiB set 1 esp on mkpart root 1GiB 100%
mkfs.fat -F32 -n BOOT ${D}p1
cryptsetup luksFormat ${D}p2
cryptsetup open ${D}p2 root
mkfs.ext4 -L nixos /dev/mapper/root
mount /dev/mapper/root /mnt && mount --mkdir -o umask=077 ${D}p1 /mnt/boot
nixos-generate-config --root /mnt --show-hardware-config > hw.nix
ip -6 addr show scope global # or `ip -4 a`
```

On an IPv6-only network, use a `scope global dynamic mngtmpaddr` address (not
the rotating `temporary` ones). IPv6 addresses need brackets in `scp` paths and
`ssh://` URLs, but not in plain `ssh`.

## 3. Host config and install (build machine)

The flake only evaluates if every host has `keys/` (`*.pub`, `known_hosts`,
`cache.pem.pub`); for now fill it with placeholders: an old host's keys, or
throwaway ones. The real keys are generated on the host in step 4.

```bash
cd /etc/nixos
H=anuramat-xyz
IP=2a02:... # the installer's address
export NIX_SSHOPTS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
D=nixos-configurations/$H

# write $D/default.nix (copy a similar host) and add $H to `hosts` in outputs.nix
mkdir -p $D/keys
scp $NIX_SSHOPTS "root@[$IP]:hw.nix" $D/hardware-configuration.nix
# placeholder keys, unless $D/keys/ is already there
t=$(mktemp -d)
ssh-keygen -q -t ed25519 -N '' -f $t/id_ed25519
nix-store --generate-binary-cache-key $H $t/cache.pem $D/keys/cache.pem.pub
cp $t/id_ed25519.pub $D/keys/
echo "$H $(cut -d' ' -f1,2 $t/id_ed25519.pub)" > $D/keys/known_hosts
git add $D outputs.nix && git commit -m "$H: init"

nix build .#nixosConfigurations.$H.config.system.build.toplevel
nix copy --to "ssh://root@[$IP]?remote-store=local%3Froot%3D/mnt" ./result
ssh $NIX_SSHOPTS root@$IP "nixos-install --system $(readlink -f result) --no-root-passwd"
ssh -t $NIX_SSHOPTS root@$IP "nixos-enter --root /mnt -c 'passwd anuramat'"
ssh $NIX_SSHOPTS root@$IP reboot
git push
```

Secrets don't decrypt until step 5; nothing needed for booting depends on them.

## 4. Keys and repo (new host)

```bash
nmtui
nix-cache-keygen # /etc/nix/cache.pem and ~/.ssh/id_ed25519
sudo tailscale up "--operator=$(whoami)"
# git rewrites https://github.com/ to ssh, which Nix's git fetcher (e.g. Cargo
# git deps) also obeys: without the key on GitHub, rebuilds fail to fetch
gh auth login -p ssh # offers to upload the ~/.ssh public key

sudo mkdir /etc/nixos && sudo chown "$USER:" /etc/nixos
git clone https://github.com/anuramat/nixos /etc/nixos
cd /etc/nixos
just nixos-pre # refreshes keys/ only
git add -A && git commit -m "$(hostname): new keys"
```

## 5. Rekey (build machine)

The new host trusts the build machine, but not the other way round yet, and
the build machine still pins the placeholder host key:

```bash
cd /etc/nixos
H=anuramat-xyz
GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null' \
  git pull $H:/etc/nixos main
(cd secrets && agenix -r)
git add secrets && git commit -m "secrets: rekey for $H" && git push
just nixos
```

## 6. Finish

- new host: `git -C /etc/nixos pull && just nixos`
- every other host: `just nixos`, to trust the new keys
- for each `builder = true` host, the root ssh config from [Problems](../README.md#problems)

todo:

```bash
# gpg --full-generate-key
# pass init $EMAIL
# firefox
# syncthing
# proton pass
# telegram
```
