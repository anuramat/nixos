# LUKS vs unattended reboots

Status: suggestion, not implemented.

## Problem

bgm5's root is LUKS-encrypted with a passphrase prompted in the initrd. sshd
lives on the encrypted root, so after any reboot the machine sits at the
console prompt, unreachable over SSH, until someone is physically present.

This conflicts with remote/unattended operation:

- a hard freeze (e.g. the 2026-07-30 GPU-reset wedge) leaves the box dead
  until physical access — and arming the hardware watchdog
  (`systemd.watchdog.runtimeTime`) is pointless while a reboot strands the
  machine at the passphrase prompt;
- power loss or a remote `reboot` has the same effect.

Note: encryption today is not actually full-disk — `/mnt/storage` (second
NVMe) is plain ext4 and holds a personal photo backup tar among bulk data.

## Option 1: TPM2 root + passphrase vault

Two tiers, same remote-recovery UX as an unencrypted core, without exposing
the OS at rest:

1. **Root: keep LUKS, add TPM2 auto-unlock.** Enroll via `systemd-cryptenroll`
   with a PCR policy (fTPM is available). The machine boots unattended:
   wifi, tailscale, and sshd come up with no interaction. Client authorized
   keys are already declared in the NixOS config (not under `/home`), so SSH
   login works before anything else is unlocked.
2. **Vault: separate passphrase-only LUKS2 volume**, `crypttab` `noauto`, no
   TPM. After a reboot, unlock over SSH (`systemd-cryptsetup@vault` prompts
   through the session). A `vault.target` gates dependent services via
   `RequiresMountsFor`, so they start on unlock instead of failing at boot.
   Holds the actually-sensitive set: photo backups (currently plaintext on
   `/mnt/storage`), sensitive `/home` subset, service state worth protecting.

Threat model:

- Disk pulled / drive disposal: everything ciphertext (root key never leaves
  the TPM; vault is passphrase-only).
- Whole machine stolen: root boots to the regular auth wall (login/SSH/network
  surface — this is the tradeoff of TPM auto-unlock); the vault stays locked
  regardless.
- Boot-chain tampering changes PCR measurements, so the TPM refuses to unseal
  and the box falls back to asking for the root passphrase — tamper-evident.

Caveats:

- PCR policy strictness is a deliberate choice: strict bindings need
  re-enrollment when the boot chain changes; loose ones weaken the guarantee.
- Keep a fallback passphrase/recovery key enrolled for root; TPM or firmware
  changes otherwise brick the boot.
- Swap is zram and `/tmp` is tmpfs on this host, so neither leaks to disk.

## Option 2: initrd SSH + Raspberry Pi relay

Keep full passphrase FDE; make the passphrase enterable remotely. A spare
always-on Pi (wifi + tailscale) sits next to bgm5, connected to `eno1` by a
direct Ethernet cable — no router involvement, which matters because bgm5
cannot be wired to the router and wifi in the initrd is effectively
unsupported.

Setup:

- Point-to-point static subnet on the cable: Pi `192.168.77.1`, bgm5
  `192.168.77.2` (/30). Any cable works (Auto-MDIX); no DHCP.
- bgm5 initrd: `boot.initrd.network` + `boot.initrd.network.ssh` on a
  distinct port (e.g. 2222) with its own host key and authorized keys;
  `r8169` in `boot.initrd.availableKernelModules`; static
  `ip=192.168.77.2:::255.255.255.252::eno1:none` kernel param. No gateway
  needed — connections originate from the Pi, everything is on-link.
- Unlock from anywhere: `ssh -J pi -p 2222 root@192.168.77.2` (Pi reachable
  over tailscale). Use ProxyJump, never a nested shell on the Pi: the inner
  session is end-to-end encrypted, so the Pi only relays ciphertext. Pin the
  initrd host key in the client config.
- Give `eno1` the same static IP in the full system, so the link doubles as
  an out-of-band path into bgm5 when its wifi stack is broken.
- Monitoring: from the Pi, "port 2222 answering" means "bgm5 awaits unlock";
  a check piping to `tgfy` closes the watchdog loop (freeze -> watchdog
  reboot -> notification -> remote unlock).

Properties:

- Stronger at-rest story than option 1: whole-machine theft still yields a
  brick; no TPM/PCR lifecycle. Evil-maid caveat unchanged from today
  (tamperable initrd on the plaintext ESP).
- The initrd sshd host key lives on the unencrypted ESP; impersonation is
  covered by client-side pinning.
- Recovery is remote but not unattended: every reboot waits for a human with
  SSH access. A watchdog reset at night leaves services down until someone
  unlocks.
- The Pi (its power and wifi) is the single point of failure for remote
  unlock — same blast radius as losing the home network entirely.

## Option 3: relay-free — initrd wifi + WireGuard to anuramat-root

No extra hardware: the initrd itself brings up wifi and a WireGuard tunnel
to anuramat-root (stable public endpoint), and the passphrase is entered
over SSH through the tunnel. WireGuard-in-initrd is documented on the NixOS
wiki (kernel module + netdev in `boot.initrd.systemd.network`); wifi in
initrd is achievable with wpa_supplicant under systemd-initrd.

Setup:

- systemd-initrd with wpa_supplicant, the `mt7925e` module and its firmware
  blobs, and DHCP.
- WireGuard netdev in the initrd with a dedicated peer key; anuramat-root
  only routes that peer (never trusts it). Unlock:
  `ssh -p 2222 root@<bgm5-wg-ip>` through the server.
- Same initrd sshd setup as option 2 (distinct port, pinned host key).

Properties:

- At-rest exposure on the plaintext ESP grows: wifi PSK + WG private key +
  initrd host key (option 2 exposes only the host key).
- Reliability is the weak point: wpa_supplicant handshake, DHCP, and the
  tunnel must all come up unattended in early boot — exactly when the
  machine is recovering from something bad. Option 2's static cable has none
  of these failure modes.
- Like option 2: remote but not unattended recovery.

Options compose: TPM2 root (option 1) with initrd SSH as fallback for when
PCR unseal fails is possible, but likely overkill.
