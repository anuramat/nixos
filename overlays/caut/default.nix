{ inputs, ... }:
_: prev: {
  caut = prev.callPackage (
    {
      rustPlatform,
      pkg-config,
      sqlite,
      # the command that the app-server fallback for an expired auth.json runs, looked up on PATH
      codex ? "codex",
    }:
    rustPlatform.buildRustPackage {
      pname = "caut";
      version = "0.1.0";
      src = inputs.caut;
      cargoLock.lockFile = "${inputs.caut}/Cargo.lock";
      patches = [
        # `cost`, `session` and `doctor` read ~/.claude and ~/.codex, ignoring CLAUDE_CONFIG_DIR and CODEX_HOME
        ./env-dirs.patch
        # `session` looks for Claude logs in a `conversations/` dir, counts a Claude response's
        # usage once per content block, and misses most Codex usage
        ./session-logs.patch
        # `doctor` and `usage` decode opaque OAuth tokens as JWTs, and flag a renewable access token
        ./credential-health.patch
        # `session` prices a session at one model's rates, ignores the 1-hour cache's write price,
        # and takes a Claude response's usage from its first line, before the output is complete
        ./session-pricing.patch
        # `cost` counts Claude's stats-cache messages and Codex log lines instead of pricing the
        # session logs
        ./cost.patch
        # Claude's fast mode and Codex's Fast tier (`service_tier = "fast"`) cost more
        ./fast-mode.patch
        # the app-server fallback's `-s read-only -a never` conflicts with wrappers that force
        # `--dangerously-bypass-approvals-and-sandbox`
        ./app-server-args.patch
      ];
      postPatch = ''
        # nightly-only `-Z threads` rustflag
        rm .cargo/config.toml
        substituteInPlace src/providers/codex/mod.rs \
          --replace-fail 'const CLI_NAME: &str = "codex";' 'const CLI_NAME: &str = "${codex}";'
      '';
      # vergen falls back to a `VERGEN_IDEMPOTENT_OUTPUT` placeholder without a git checkout
      env.VERGEN_GIT_SHA = inputs.caut.rev;
      env.VERGEN_GIT_DIRTY = "false";
      nativeBuildInputs = [ pkg-config ];
      buildInputs = [ sqlite ];
      # 11 LTO'd integration test binaries; upstream `cargo install` skips them too
      doCheck = false;
    }
  ) { };
}
