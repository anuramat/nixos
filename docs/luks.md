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

## Suggested solution: TPM2 root + passphrase vault

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
