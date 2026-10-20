{ inputs, lib, ... }:
final: prev: {
  caut = prev.rustPlatform.buildRustPackage {
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
      # `cost` counts Claude's stats-cache messages and Codex log lines instead of pricing the
      # session logs; `session` prices a session at one model's rates, and takes a Claude
      # response's usage from its first line, before the output is complete
      ./cost.patch
    ];
    # nightly-only `-Z threads` rustflag
    postPatch = "rm .cargo/config.toml";
    # vergen falls back to a `VERGEN_IDEMPOTENT_OUTPUT` placeholder without a git checkout
    env.VERGEN_GIT_SHA = inputs.caut.rev;
    env.VERGEN_GIT_DIRTY = "false";
    nativeBuildInputs = [
      prev.pkg-config
      prev.makeWrapper
    ];
    buildInputs = [ prev.sqlite ];
    # 11 LTO'd integration test binaries; upstream `cargo install` skips them too
    doCheck = false;
    # the codex on PATH is the agent sandbox wrapper, whose forced
    # --dangerously-bypass-approvals-and-sandbox conflicts with the `-s read-only -a never` of
    # caut's `codex app-server` fallback for an expired auth.json
    postFixup = "wrapProgram $out/bin/caut --prefix PATH : ${lib.makeBinPath [ final.codex ]}";
  };
}
