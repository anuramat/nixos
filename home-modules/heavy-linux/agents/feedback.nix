# out-of-band channel for agents to report problems with their environment
# (stale or unclear instructions, sandbox limitations, ...), to be fixed later
# in this repo; read with `journalctl -t agent-feedback`
{ pkgs, ... }:
let
  feedback =
    pkgs.writers.writePython3Bin "agent-feedback"
      {
        libraries = [ pkgs.python3Packages.systemd-python ];
      }
      ''
        import os
        import subprocess
        import sys
        from systemd import journal

        # the running system's revision, to tell stale reports from fixed ones
        rev = subprocess.run(
            ["nixos-version", "--configuration-revision"],
            capture_output=True,
            text=True,
        ).stdout.strip()
        journal.send(
            f"[{os.getcwd()} @ {rev}] {sys.stdin.read().strip()}",
            SYSLOG_IDENTIFIER="agent-feedback",
        )
      '';
in
{
  home.packages = [ feedback ];
  # a socket accepts messages through a read-only bind
  agents.sandbox.roDirs = [ "/run/systemd/journal/socket" ];
}
