I want to add the `-DLLAMA_LLGUIDANCE=ON` cmake flag to the package in nixpkgs, but it fails on trying to use network:

[3/357] Performing download step (git clone) for 'llguidance_ext'
FAILED: llguidance/src/llguidance_ext-stamp/llguidance_ext-download /build/source/build/llguidance/src/llguidance_ext-stamp/llguidance_ext-download 
cd /build/source/build/llguidance && /nix/store/29ax4k0a83zhz43lb73cv610d95wdsx1-cmake-3.31.6/bin/cmake -DCMAKE_MESSAGE_LOG_LEVEL=VERBOSE -P /build/source/build/llguidance/tmp/llguidance_ext-gitclon>
Cloning into 'source'...
fatal: unable to access 'https://github.com/guidance-ai/llguidance/': Could not resolve host: github.com
Cloning into 'source'...
fatal: unable to access 'https://github.com/guidance-ai/llguidance/': Could not resolve host: github.com
Cloning into 'source'...
fatal: unable to access 'https://github.com/guidance-ai/llguidance/': Could not resolve host: github.com
Had to git clone more than once: 3 times.
CMake Error at tmp/llguidance_ext-gitclone.cmake:50 (message):
  Failed to clone repository: 'https://github.com/guidance-ai/llguidance'

Nix builds run with no network. `-DLLAMA_LLGUIDANCE=ON` makes llama.cpp’s CMake run an `ExternalProject_Add()` that tries to `git clone https://github.com/guidance-ai/llguidance`, which fails under Nix. Fix: prefetch `llguidance`, then patch the ExternalProject to use the local source and disable its download step. Also add Rust to build inputs because LLGuidance is a Rust lib. ([GitHub][1])

### Minimal overlay

```nix
# overlays/llama-cpp-llguidance.nix
self: super:
let
  llguidanceSrc = super.fetchFromGitHub {
    owner = "guidance-ai";
    repo  = "llguidance";
    # pick a fixed commit
    rev   = "PUT-COMMIT-HERE";
    hash  = "sha256-REPLACE";
  };
in {
  llama-cpp = super.llama-cpp.overrideAttrs (old: {
    # enable the feature
    cmakeFlags = (old.cmakeFlags or []) ++ [
      "-DLLAMA_LLGUIDANCE=ON"
    ];

    # llguidance is Rust; provide toolchain
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
      super.rustc
      super.cargo
    ];

    postPatch = (old.postPatch or "") + ''
      # Rewrite the ExternalProject for llguidance to be offline.
      # Replace its GIT_* download with a local SOURCE_DIR and empty DOWNLOAD/UPDATE commands.
      python <<'PY'
import io, re, sys, pathlib
p = pathlib.Path("common/CMakeLists.txt")
s = p.read_text()
pat = r'(ExternalProject_Add\\(\\s*llguidance_ext[\\s\\S]*?\\))'
m = re.search(pat, s)
if not m: sys.exit(0)
blk = m.group(1)
# remove any GIT_* lines
blk2 = re.sub(r'\\n\\s*GIT_\\w+[^\\n]*', '', blk)
# ensure SOURCE_DIR and disable DL/UPDATE
injected = (
  "\\n  SOURCE_DIR ${llguidanceSrc}\\n"
  "  DOWNLOAD_COMMAND \"\"\\n"
  "  UPDATE_COMMAND \"\"\\n"
)
blk2 = re.sub(r'ExternalProject_Add\\(\\s*llguidance_ext', r'ExternalProject_Add(llguidance_ext' + injected, blk2)
s = s.replace(blk, blk2)
p.write_text(s)
PY
    '';
  });
}
```

### Usage

```nix
# configuration.nix or flake overlay
nixpkgs.overlays = [ (import ./overlays/llama-cpp-llguidance.nix) ];
```

This forces CMake to use the vendored `llguidance` and keeps the build offline, satisfying Nix. References: llama.cpp exposes `LLAMA_LLGUIDANCE` and pulls `guidance-ai/llguidance`; ExternalProject supports `SOURCE_DIR` with `DOWNLOAD_COMMAND ""` for offline builds. ([GitHub][1])

If you prefer not to patch with Python: do the same transformation with `substituteInPlace` or `awk`.

[1]: https://github.com/ggml-org/llama.cpp/issues/15833?utm_source=chatgpt.com "Feature Request: Enable LLGuidance in published docker ..."

