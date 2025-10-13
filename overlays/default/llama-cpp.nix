inputs:
(
  final: prev:
  let
    llguidanceSrc = prev.fetchFromGitHub {
      owner = "guidance-ai";
      repo = "llguidance";
      rev = "866e6921fd11fbddd604f2193055c62146c412cc";
      hash = "sha256-cwe2WkCMEwAO8zYUOSYGE4Px++MLQaSoK6878jsJhKQ=";
    };
    llguidanceVendor = prev.rustPlatform.fetchCargoVendor {
      src = llguidanceSrc;
      hash = "sha256-Or478a6/kKLJdEs38QlyUxmW8pfAk7thHsmL25uKByY=";
    };
    unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
    llguidanceSetup = prev.writeShellScript "llguidance-setup.sh" ''
          set -euo pipefail
          src=$1
          rm -rf "$src"
          mkdir -p "$src"
          cp -R ${llguidanceSrc}/. "$src/"
          chmod -R u+w "$src"
          rm -rf "$src/vendor"
          mkdir -p "$src/vendor"
          cp -R ${llguidanceVendor}/. "$src/vendor/"
          rm -rf "$src/.cargo-home"
          mkdir -p "$src/.cargo-home"
          cat > "$src/.cargo-home/config.toml" <<CFG
      [source.crates-io]
      replace-with = "vendored-sources"

      [source.vendored-sources]
      directory = "$src/vendor"
      CFG
          sed -i '/"python_ext",/d' "$src/Cargo.toml"
          sed -i '/"python_ext"/d' "$src/Cargo.toml"
    '';
  in
  {
    llama-cpp = prev.llama-cpp.overrideAttrs (old: rec {
      version = "6750";
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [
        "-DLLAMA_LLGUIDANCE=ON"
      ];
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        unstable.rustc
        unstable.cargo
      ];
      postPatch = (old.postPatch or "") + ''
              patch -p1 <<'EOF'
        diff --git a/common/CMakeLists.txt b/common/CMakeLists.txt
        index fe290bf..312715c 100644
        --- a/common/CMakeLists.txt
        +++ b/common/CMakeLists.txt
        @@ -147,14 +147,13 @@ if (LLAMA_LLGUIDANCE)
             endif()

             ExternalProject_Add(llguidance_ext
        -        GIT_REPOSITORY https://github.com/guidance-ai/llguidance
        -        # v1.0.1:
        -        GIT_TAG d795912fedc7d393de740177ea9ea761e7905774
        -        PREFIX ''${CMAKE_BINARY_DIR}/llguidance
        -        SOURCE_DIR ''${LLGUIDANCE_SRC}
        +        PREFIX ''${CMAKE_BINARY_DIR}/llguidance
        +        SOURCE_DIR ''${LLGUIDANCE_SRC}
        +        DOWNLOAD_COMMAND ""
        +        PATCH_COMMAND ${llguidanceSetup} ''${LLGUIDANCE_SRC}
                 BUILD_IN_SOURCE TRUE
                 CONFIGURE_COMMAND ""
        -        BUILD_COMMAND cargo build --release --package llguidance
        +        BUILD_COMMAND ''${CMAKE_COMMAND} -E env CARGO_HOME=''${LLGUIDANCE_SRC}/.cargo-home CARGO_NET_OFFLINE=true cargo build --offline --release --package llguidance
                 INSTALL_COMMAND ""
        -        BUILD_BYPRODUCTS ''${LLGUIDANCE_PATH}/''${LLGUIDANCE_LIB_NAME} ''${LLGUIDANCE_PATH}/llguidance.h
        +        BUILD_BYPRODUCTS ''${LLGUIDANCE_PATH}/''${LLGUIDANCE_LIB_NAME} ''${LLGUIDANCE_PATH}/llguidance.h
                 UPDATE_COMMAND ""
             )
        EOF
      '';
      src = prev.fetchFromGitHub {
        owner = "ggml-org";
        repo = "llama.cpp";
        tag = "b${version}";
        hash = "sha256-aoyJGyxvyoU37AGycd540w4b2DC4wNA7GkzmwaZKYRU=";
        leaveDotGit = true;
        postFetch = ''
          git -C "$out" rev-parse --short HEAD >$out/COMMIT
          find "$out" -name .git -print0 | xargs -0 rm -rf
        '';
      };
    });
  }
)
