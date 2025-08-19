# Username Customization Guide

This NixOS configuration now supports custom usernames! The username is no longer hardcoded to "anuramat".

## How to Use a Different Username

### Method 1: Override in Host Configuration

In your host configuration file (e.g., `nixos-configurations/my-host/default.nix`), add:

```nix
{
  # Override the default username
  userConfig = {
    username = "alice";
    fullName = "Alice Smith";
    email = "alice@example.com";
    
    # Optional: customize paths
    personalPaths = {
      notes = "/home/alice/Documents/notes";
      books = "/home/alice/Documents/books";
      todo = "/home/alice/Documents/todo.txt";
    };
    
    # Optional: different timezone
    timezone = "America/New_York";
  };
}
```

### Method 2: Create Your Own Host Configuration

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

The personal module (`anuramat.nix`) is only loaded when the username is "anuramat". 
For other usernames, you can:

1. Create your own module: `home-modules/${username}.nix`
2. Set `userConfig.enablePersonalModules = true`
3. The system will automatically load your personal module if it exists

## Default Values

If not specified, these defaults are used for backward compatibility:

- `username`: "anuramat"
- `fullName`: "Arsen Nuramatov"
- `email`: "arsenovich@proton.me"
- `timezone`: "Europe/Berlin"
- `personalPaths.notes`: `/home/${username}/notes`
- `personalPaths.books`: `/home/${username}/books`
- `personalPaths.todo`: `/home/${username}/notes/todo.txt`

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
    timezone = "America/Los_Angeles";
    
    personalPaths = {
      notes = "/home/alice/Nextcloud/notes";
      books = "/home/alice/Library/books";
      todo = "/home/alice/Nextcloud/todo.txt";
    };
    
    enablePersonalModules = true;  # Will load home-modules/alice.nix if it exists
  };

  system.stateVersion = "24.05";
  home-manager.users.alice.home.stateVersion = "24.11";
}