{ pkgs, lib }:
let
  hax = import ../../../hax/hosts.nix {
    inherit lib;
    inputs.self.nixosConfigurations = mockConfigs;
  };

  # Mock data for testing
  mockConfigs = {
    host1 = {
      config = {
        nix.distributedBuilds = false;
        nixpkgs.hostPlatform.system = "x86_64-linux";
      };
    };
    host2 = {
      config = {
        nix.distributedBuilds = true;
        nixpkgs.hostPlatform.system = "aarch64-linux";
      };
    };
  };

  # Mock filesystem structure
  mockPath = pkgs.runCommand "mock-hosts" { } ''
    mkdir -p $out/host1/keys $out/host2/keys $out/host3/keys

    # Host1 setup
    echo "{ server = false; }" >$out/host1/meta.nix
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHost1Key host1" >$out/host1/keys/host_keys
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClient1Key" >$out/host1/keys/client1.pub
    echo "host1-cache-key" >$out/host1/keys/cache.pem.pub

    # Host2 setup
    echo "{ server = true; }" >$out/host2/meta.nix
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQHost2Key host2" >$out/host2/keys/host_keys
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClient2Key" >$out/host2/keys/client2.pub
    echo "host2-cache-key" >$out/host2/keys/cache.pem.pub

    # Host3 setup (minimal)
    echo "{ server = false; }" >$out/host3/meta.nix
    touch $out/host3/keys/host_keys
    touch $out/host3/keys/cache.pem.pub

    # Create external_keys.nix to test filtering
    echo "# external keys" >$out/external_keys.nix
  '';
in
{
  # Test getHostnames
  testGetHostnames = {
    expr = hax.getHostnames mockPath;
    expected = [
      "host1"
      "host2"
      "host3"
    ];
  };

  # Test getAllHostkeys
  testGetAllHostkeys = {
    expr = hax.getAllHostkeys mockPath;
    expected = [
      "AAAAC3NzaC1lZDI1NTE5AAAAIHost1Key host1"
      "AAAAB3NzaC1yc2EAAAADAQABAAABAQHost2Key host2"
    ];
  };

  # Test getAllKeys
  testGetAllKeys = {
    expr = hax.getAllKeys mockPath |> builtins.length;
    expected = 2;
  };

  # Test mkCluster basic structure
  testMkClusterStructure = {
    expr =
      let
        cluster = hax.mkCluster mockPath [ "host1" "host2" "host3" ] "host1";
      in
      {
        hasThis = cluster.this != null;
        thisName = cluster.this.name;
        hostnamesCount = builtins.length cluster.hostnames;
        builderUsername = cluster.builderUsername;
      };
    expected = {
      hasThis = true;
      thisName = "host1";
      hostnamesCount = 3;
      builderUsername = "builder";
    };
  };

  # Test mkCluster.this properties
  testMkClusterThis = {
    expr =
      let
        cluster = hax.mkCluster mockPath [ "host1" "host2" ] "host1";
      in
      {
        name = cluster.this.name;
        builder = cluster.this.builder;
        server = cluster.this.server;
        desktop = cluster.this.desktop;
        platform = cluster.this.platform;
        hasCacheKey = cluster.this.cacheKey != "";
      };
    expected = {
      name = "host1";
      builder = true;
      server = false;
      desktop = true;
      platform = "x86_64-linux";
      hasCacheKey = true;
    };
  };

  # Test mkCluster builders filtering
  testMkClusterBuilders = {
    expr =
      let
        cluster = hax.mkCluster mockPath [ "host1" "host2" ] "host2";
      in
      {
        builderCount = builtins.length cluster.builders;
        builderNames = map (x: x.name) cluster.builders;
      };
    expected = {
      builderCount = 1;
      builderNames = [ "host1" ];
    };
  };

  # Test mkCluster substituters generation
  testMkClusterSubstituters = {
    expr =
      let
        cluster = hax.mkCluster mockPath [ "host1" "host2" ] "host2";
      in
      cluster.substituters;
    expected = [ "ssh-ng://host1?priority=50" ];
  };

  # Test mkCluster trusted-public-keys
  testMkClusterTrustedKeys = {
    expr =
      let
        cluster = hax.mkCluster mockPath [ "host1" "host2" "host3" ] "host1";
      in
      {
        keyCount = builtins.length cluster.trusted-public-keys;
        hasHost2Key = builtins.any (x: lib.strings.hasInfix "host2" x) cluster.trusted-public-keys;
      };
    expected = {
      keyCount = 2; # host2 and host3's keys (empty counts as a key)
      hasHost2Key = true;
    };
  };

  # Test mkCluster clientKeyFiles aggregation
  testMkClusterClientKeys = {
    expr =
      let
        cluster = hax.mkCluster mockPath [ "host1" "host2" ] "host1";
      in
      cluster.clientKeyFiles |> builtins.length;
    expected = 1; # Only other machines' keys
  };

  # Test mkCluster hostKeysFiles
  testMkClusterHostKeysFiles = {
    expr =
      let
        cluster = hax.mkCluster mockPath [ "host1" "host2" ] "host1";
      in
      cluster.hostKeysFiles |> builtins.length;
    expected = 1; # Only host2's keys file
  };
}
