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
    blink-cmp-avante = {
      flake = false;
      url = "github:Kaiser-Yang/blink-cmp-avante/v0.1.0";
    };
    claude-desktop = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:k3d3/claude-desktop-linux-flake";
    };
    crush = {
      flake = false;
      url = "github:charmbracelet/crush/v0.2.1";
    };
    ctrlsn = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
    };
    diriger = {
      flake = false;
      url = "github:anuramat/diriger";
    };
    figtree = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/figtree.nvim";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    gothink = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/gothink";
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
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
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
    mdformat-myst = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/mdformat-myst/dev";
    };
    mdmath = {
      url = "github:anuramat/mdmath.nvim";
    };
    modagent = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:anuramat/modagent";
    };
    mods = {
      url = "github:anuramat/mods";
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
      url = "github:nix-community/nixvim";
    };
    spicetify-nix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
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
    todo = {
      flake = false;
      url = "github:anuramat/todo";
    };
    tt-schemes = {
      flake = false;
      url = "github:tinted-theming/schemes";
    };
  };
}
