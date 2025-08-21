# ==============================================================================
# ACTIVATION SCRIPT TESTS
# ==============================================================================
#
# Test suite for home-modules/default/lib.nix activation script functions:
# - mkJqActivationScript (JSON operations)
# - mkYqActivationScript (YAML operations)
# - mkGenericActivationScript (file copying)
#
# Test Categories:
# - STRUCTURE: DAG entry structure and script content generation
# - EXECUTION: Real execution with jq/yq/bash to verify behavior
#
# This comprehensive test suite enables safe refactoring by providing extensive
# verification of behavior that must be preserved during any changes.
# ==============================================================================

{ pkgs, lib }:
let
  # Import shared test library and utilities
  testLib = import ./activation-scripts/lib.nix { inherit pkgs lib; };

  # Import test modules
  structureTests = import ./activation-scripts/structure-tests.nix { inherit testLib; };
  executionTests = import ./activation-scripts/execution-tests.nix { inherit testLib; };
in
# Combine all test suites into a single attribute set
structureTests
// executionTests
// {
}
