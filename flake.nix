{
  inputs = {
    agenix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:yaxitech/ragenix";
    };
    avante = {
      flake = false;
      url = "github:yetone/avante.nvim/main";
    };
    base16-mutt = {
      flake = false;
      url = "github:josephholsten/base16-mutt";
    };
    blink-cmp-avante = {
      flake = false;
      url = "github:Kaiser-Yang/blink-cmp-avante";
    };
    ctrlsn = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
    };
    deadnix = {
      url = "github:astro/deadnix/main";
    };
    duckduckgo-mcp-server = {
      url = "github:anuramat/duckduckgo-mcp-server/dev";
    };
    ez-configs = {
      inputs = {
        flake-parts = {
          follows = "flake-parts";
        };
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:ehllie/ez-configs";
    };
    figtree = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/figtree.nvim";
    };
    files = {
      url = "github:mightyiam/files";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
    };
    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/home-manager/release-25.05";
    };
    html2text = {
      url = "github:anuramat/html2text/dev";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };
    mcp-nixos = {
      url = "github:utensils/mcp-nixos";
    };
    mcphub = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:ravitemer/mcphub.nvim";
    };
    mods = {
      url = "github:anuramat/mods/dev";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };
    nil = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:oxalica/nil/main";
    };
    nix-topology = {
      url = "github:oddlama/nix-topology";
    };
    nix-unit = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/nix-unit/v2.30.0";
    };
    nixd = {
      url = "github:nix-community/nixd/2.7.0";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    nixvim = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/nixvim/nixos-25.05";
    };
    nur = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/NUR";
    };
    protonmail-bridge = {
      flake = false;
      url = "github:anuramat/proton-bridge/dev";
    };
    spicetify-nix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:Gerg-L/spicetify-nix";
    };
    statix = {
      url = "github:oppiliappan/statix/master";
    };
    stylix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:danth/stylix/release-25.05";
    };
    subcat = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/subcat";
    };
    todo = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/todo";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
    };
    tt-schemes = {
      flake = false;
      url = "github:tinted-theming/schemes";
    };
    zotero-mcp = {
      url = "github:anuramat/zotero-mcp";
    };
  };
  outputs = args: import ./outputs.nix args;
}
