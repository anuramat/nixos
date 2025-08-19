{ pkgs, lib }:
let
  # Mock inputs
  mockInputs = {
    self = {
      consts = {
        builderUsername = "builder";
        cacheFilename = "cache.pem.pub";
        cfgRoot = pkgs.runCommand "mock-cfg-root" { } ''
          mkdir -p $out

          # Host1 with builder and keys
          mkdir -p $out/host1/keys
          echo "ssh-rsa AAAAB3NzaC1yc2E host1-cache-key" >$out/host1/keys/cache.pem.pub
          echo "ssh-rsa AAAAB3NzaC1yc2E host1-client-key" >$out/host1/keys/client1.pub
          echo "ssh-rsa AAAAB3NzaC1yc2E host1-client-key2" >$out/host1/keys/client2.pub
          cat >$out/host1/keys/host_keys <<EOF
          host1.example.com ssh-rsa AAAAB3NzaC1yc2E host1-key
          host1.example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5 host1-ed-key
          EOF

          # Host2 without builder
          mkdir -p $out/host2/keys
          echo "ssh-rsa AAAAB3NzaC1yc2E host2-cache-key" >$out/host2/keys/cache.pem.pub
          echo "ssh-rsa AAAAB3NzaC1yc2E host2-client-key" >$out/host2/keys/client.pub
          cat >$out/host2/keys/host_keys <<EOF
          host2.example.com ssh-rsa AAAAB3NzaC1yc2E host2-key
          EOF

          # Host3 with builder
          mkdir -p $out/host3/keys
          echo "ssh-rsa AAAAB3NzaC1yc2E host3-cache-key" >$out/host3/keys/cache.pem.pub
          cat >$out/host3/keys/host_keys <<EOF
          host3.example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5 host3-key
          EOF
        '';
      };
      nixosConfigurations = {
        host1 = {
          config = {
            nixpkgs.hostPlatform.system = "x86_64-linux";
            users.users.builder = { }; # Has builder user
            networking.hostName = "host1";
          };
        };
        host2 = {
          config = {
            nixpkgs.hostPlatform.system = "aarch64-linux";
            users.users = { }; # No builder user
            networking.hostName = "host2";
          };
        };
        host3 = {
          config = {
            nixpkgs.hostPlatform.system = "x86_64-linux";
            users.users.builder = { }; # Has builder user
            networking.hostName = "host3";
          };
        };
      };
    };
  };

  hax = import ../../../hax/hosts.nix {
    inherit lib;
    inputs = mockInputs;
  };
in
{
  # Test mkOthers - get other hosts excluding current
  testMkOthers = {
    expr = hax.mkOthers mockInputs "host1";
    expected = {
      host2 = {
        system = "aarch64-linux";
        builder = false;
      };
      host3 = {
        system = "x86_64-linux";
        builder = true;
      };
    };
  };

  # Test mkOthers with different current host
  testMkOthersHost2 = {
    expr = hax.mkOthers mockInputs "host2";
    expected = {
      host1 = {
        system = "x86_64-linux";
        builder = true;
      };
      host3 = {
        system = "x86_64-linux";
        builder = true;
      };
    };
  };

  # Test mkCacheKey
  testMkCacheKey = {
    expr = hax.mkCacheKey "host1";
    expected = "ssh-rsa AAAAB3NzaC1yc2E host1-cache-key\n";
  };

  testMkCacheKeyHost2 = {
    expr = hax.mkCacheKey "host2";
    expected = "ssh-rsa AAAAB3NzaC1yc2E host2-cache-key\n";
  };

  # Test mkClientKeyFiles
  testMkClientKeyFiles = {
    expr = hax.mkClientKeyFiles "host1" |> builtins.length;
    expected = 2; # client1.pub and client2.pub
  };

  testMkClientKeyFilesHost2 = {
    expr = hax.mkClientKeyFiles "host2" |> builtins.length;
    expected = 1; # client.pub
  };

  testMkClientKeyFilesHost3 = {
    expr = hax.mkClientKeyFiles "host3";
    expected = [ ]; # No client keys
  };

  # Test mkKnownHostsFiles
  testMkKnownHostsFiles = {
    expr =
      hax.mkKnownHostsFiles [
        "host1"
        "host2"
      ]
      |> builtins.length;
    expected = 2; # Two host_keys files
  };

  # Test mkHostKeys
  testMkHostKeys = {
    expr = hax.mkHostKeys [ "host1" ] |> builtins.sort builtins.lessThan;
    expected = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5 host1-ed-key"
      "ssh-rsa AAAAB3NzaC1yc2E host1-key"
    ];
  };

  testMkHostKeysMultiple = {
    expr =
      hax.mkHostKeys [
        "host1"
        "host2"
        "host3"
      ]
      |> builtins.length;
    expected = 4; # 2 from host1 + 1 from host2 + 1 from host3
  };

  # Test mkKeyFiles
  testMkKeyFiles = {
    expr =
      hax.mkKeyFiles [
        "host1"
        "host2"
      ]
      |> builtins.length;
    expected = 3; # client1.pub, client2.pub from host1 and client.pub from host2
  };

  testMkKeyFilesSingle = {
    expr = hax.mkKeyFiles [ "host3" ];
    expected = [ ]; # host3 has no client keys
  };

  # Test mkSubstituters
  testMkSubstituters = {
    expr = hax.mkSubstituters [
      "builder1.example.com"
      "builder2.example.com"
    ];
    expected = [
      "ssh-ng://builder1.example.com?priority=50"
      "ssh-ng://builder2.example.com?priority=50"
    ];
  };

  testMkSubstitutersEmpty = {
    expr = hax.mkSubstituters [ ];
    expected = [ ];
  };

  # Test edge cases
  testMkOthersEmpty = {
    expr =
      let
        emptyInputs = {
          self.nixosConfigurations = {
            onlyhost = {
              config = {
                nixpkgs.hostPlatform.system = "x86_64-linux";
                users.users = { };
                networking.hostName = "onlyhost";
              };
            };
          };
        };
      in
      hax.mkOthers emptyInputs "onlyhost";
    expected = { };
  };

  # Test with all hosts having builders
  testMkOthersAllBuilders = {
    expr =
      let
        result = hax.mkOthers mockInputs "host1";
      in
      {
        host2HasBuilder = result.host2.builder;
        host3HasBuilder = result.host3.builder;
      };
    expected = {
      host2HasBuilder = false;
      host3HasBuilder = true;
    };
  };
}
