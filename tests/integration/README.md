# Integration Tests for Username Refactoring

## Overview

These tests ensure that username configuration changes don't break the NixOS configurations.

## Test Files

- `username.nix` - Unit tests for username configuration with different values
- `mock-nixos-module.nix` - Mock NixOS module for testing username propagation

## Running Tests

### Unit Tests

Run username configuration unit tests:

```bash
just test
```

## What's Tested

- Username propagates to user creation
- Username propagates to home-manager
- Username propagates to services (getty autologin)
- Username propagates to git configuration
- Groups are correctly assigned
- Multiple usernames can coexist without interference
- Special characters in usernames work correctly
