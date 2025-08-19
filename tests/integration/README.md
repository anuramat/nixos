# Integration Tests for Username Refactoring

## Overview

These tests ensure that username configuration changes don't break the NixOS configurations.

## Test Files

- `username.nix` - Unit tests for username configuration with different values
- `mock-nixos-module.nix` - Mock NixOS module for testing username propagation
- `build-matrix.sh` - Tests building all host configurations
- `snapshot-username.sh` - Captures current configuration state for comparison

## Running Tests

### Unit Tests
Run username configuration unit tests:
```bash
just test-integration
# or
just test
```

### Build Matrix Test
Test that all host configurations build:
```bash
just test-matrix
```

### Snapshot Tests
Create snapshots before refactoring:
```bash
just test-snapshot
```

After refactoring, compare with snapshots:
```bash
./tests/integration/snapshots/compare.sh
```

## Test Strategy

1. **Before Refactoring**: Run `just test-snapshot` to capture current state
2. **During Refactoring**: Run `just test` after each change
3. **After Refactoring**: Run all tests to ensure nothing broke

## What's Tested

- Username propagates to user creation
- Username propagates to home-manager
- Username propagates to services (getty autologin)
- Username propagates to git configuration
- Groups are correctly assigned
- Multiple usernames can coexist without interference
- Special characters in usernames work correctly