# Username Customization Guide

This NixOS configuration now supports custom usernames! The username is no longer hardcoded to "anuramat".

## How to Use a Different Username

### Method 1: Set User Info in userConfig

In your host configuration file (e.g., `nixos-configurations/my-host/default.nix`), add:

```nix
{
  userConfig = {
    username = "alice";
    fullName = "Alice Smith";
    email = "alice@example.com";
  };
}
```

### Method 2: Use Git Settings as Defaults (Recommended)

Create a home module `home-modules/alice.nix` with:

```nix
{
  programs.git = {
    userName = "Alice Smith";
    userEmail = "alice@example.com";
  };
}
```

Then in your host configuration:

```nix
{
  userConfig = {
    username = "alice";
    # fullName and email will automatically default to git settings
  };
}
```

**How it works**: Git settings provide the defaults. You can still override them by setting `userConfig.fullName` or `userConfig.email` explicitly if needed.

### Method 3: Create Your Own Host Configuration

1. Copy an existing host configuration:
```bash
cp -r nixos-configurations/anuramat-ll7 nixos-configurations/my-hostname
```

2. Edit `nixos-configurations/my-hostname/default.nix`:
   - Change `networking.hostName` to match your hostname
   - Add `userConfig` settings as shown above

3. Rebuild:
```bash
sudo nixos-rebuild switch
```

## What Gets Configured

When you set a custom username, the following are automatically configured:

- **System user**: Created with the specified username
- **Home directory**: `/home/${username}`
- **Home-manager**: Configuration for your user
- **Git configuration**: Your name and email
- **SSH access**: Authorized keys
- **Auto-login**: Console auto-login user
- **System services**: Access to required services
- **Groups**: wheel, networkmanager, docker, etc.

## Personal Modules

The system automatically loads a home module matching your username from `home-modules/${username}.nix`. For example:

- `userConfig.username = "anuramat"` loads `home-modules/anuramat.nix`
- `userConfig.username = "alice"` loads `home-modules/alice.nix`

Create your own home module to customize your user environment.

## How Defaults Work

The system uses a simple default mechanism:

1. **Username is required**: You must set `userConfig.username`
2. **fullName**: Defaults to `programs.git.userName` if not explicitly set
3. **email**: Defaults to `programs.git.userEmail` if not explicitly set

You can override the git defaults by setting `userConfig.fullName` or `userConfig.email` explicitly. Both git settings and userConfig can coexist without conflicts.

### Error Handling

You'll get an error if neither git settings nor userConfig provide the required values:

- `"No full name provided. Set either userConfig.fullName or programs.git.userName."`
- `"No email provided. Set either userConfig.email or programs.git.userEmail."`

## Backward Compatibility

For existing `anuramat` configurations, nothing changes - the git settings in `home-modules/anuramat.nix` are used automatically as defaults.

## Testing Different Usernames

Before committing to changes, you can test with:

```bash
# Check what would be built
nix build .#nixosConfigurations.your-host.config.system.build.toplevel --dry-run

# Run tests
just test

# Check specific values
nix eval .#nixosConfigurations.your-host.config.userConfig.username
```

## Migration from Hardcoded Username

If you're migrating from the old hardcoded system:

1. Your existing configuration will continue to work (defaults to "anuramat")
2. You can gradually migrate by adding `userConfig` settings
3. All existing functionality is preserved

## Troubleshooting

If something doesn't work:

1. Check that your hostname matches the directory name
2. Verify userConfig is properly set in your host configuration
3. Run `just test-snapshot` and compare with baseline
4. Check build errors with `--show-trace` flag

## Example: Complete User Configuration

### Option A: Using userConfig
```nix
# In nixos-configurations/alice-laptop/default.nix
{
  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    ./hardware-configuration.nix
  ];

  networking.hostName = "alice-laptop";
  
  userConfig = {
    username = "alice";
    fullName = "Alice Smith";
    email = "alice@company.com";
  };

  system.stateVersion = "24.05";
  home-manager.users.anuramat.home.stateVersion = "24.11";
}
```

### Option B: Using Git Defaults (Recommended)
```nix
# In nixos-configurations/alice-laptop/default.nix  
{
  imports = [
    inputs.self.nixosModules.default
    inputs.self.nixosModules.local
    ./hardware-configuration.nix
  ];

  networking.hostName = "alice-laptop";
  
  userConfig = {
    username = "alice";
    # fullName and email will default to git settings
  };

  system.stateVersion = "24.05";
  home-manager.users.anuramat.home.stateVersion = "24.11";
}
```

```nix
# In home-modules/alice.nix
{
  programs.git = {
    userName = "Alice Smith";
    userEmail = "alice@company.com";
  };
  
  # Add other personal home-manager configuration here
}
```

### Option C: Mixed Approach
```nix
# You can also mix and match
{
  userConfig = {
    username = "alice";
    fullName = "Alice Smith-Jones"; # Override git userName
    # email will default to programs.git.userEmail
  };
}
```