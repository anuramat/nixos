#!/usr/bin/env bash

export TRITON_LIBCUDA_PATH=$(nix eval --raw nixpkgs#cudaPackages.cuda_cudart --impure)/lib
export LIBRARY_PATH=/run/opengl-driver/lib:$(nix eval --raw nixpkgs#cudaPackages.cuda_cudart --impure)/lib
export C_INCLUDE_PATH=$(nix eval --raw nixpkgs#cudaPackages.cuda_cudart --impure)/include
export CPLUS_INCLUDE_PATH=$(nix eval --raw nixpkgs#cudaPackages.cuda_cudart --impure)/include
uv run --with vllm vllm serve "Qwen/Qwen3-Omni-30B-A3B-Instruct" --trust-remote-code --cpu-offload-gb 99999 --max-model-len 8192
