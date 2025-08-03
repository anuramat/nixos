{
  outputs = args: import ./outputs.nix args;
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
      url = "github:yetone/avante.nvim/v0.0.27";
    };
    claude-desktop = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:k3d3/claude-desktop-linux-flake";
    };
    codex = {
      url = "github:openai/codex";
    };
    copilot-api = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/copilot-api";
    };
    crush = {
      flake = false;
      url = "github:charmbracelet/crush/nightly";
    };
    ctrlsn = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/home-manager/release-25.05";
    };
    mcp-nixos = {
      url = "github:utensils/mcp-nixos";
    };
    mdformat-myst = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/mdformat-myst/dev";
    };
    mdmath = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/mdmath.nvim";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };
    nil = {
      url = "github:oxalica/nil/main";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };
    nixpkgs-old = {
      url = "github:nixos/nixpkgs/nixos-24.11";
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
      url = "github:nix-community/nixvim";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
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
    tt-schemes = {
      flake = false;
      url = "github:tinted-theming/schemes";
    };
  };
}
