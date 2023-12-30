{
  nixConfig = {
    extra-substituters = [
      #"...."
    ];
    extra-trusted-public-keys = [
      #"..."
    ];
  };

  inputs = {
    ##- CORE COMPONENTS -##
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix.url = "github:nixos/nix";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    byos.url = "github:null0xeth/byos";

    #-> Systems to build for
    systems.url = "github:nix-systems/default";

    #-> Age encryption for secrets
    agenix.url = "github:ryantm/agenix";

    #-> Automatic secret rekeying
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #-> Binary caching
    cachix = {
      url = "github:cachix/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #-> Dotfiles management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #-> Useful functions for nixos-configurations.
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #-> Nobody builds that locally..
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-parts,
    nixpkgs,
    systems,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.pre-commit-hooks-nix.flakeModule ./parts];

      systems = import systems;

      perSystem = {
        config,
        pkgs,
        system,
        inputs',
        ...
      }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
          #overlays = [];
        };

        # Provides the agenix-rekey app on `nix run .`
        apps = {
          agenix-rekey = {
            type = "app";
            program = "${nixpkgs.lib.getExe inputs'.agenix-rekey.packages.default}"; #${system}.default}";
          };
        };

        # Provides checks for `nix flake check`
        pre-commit = {
          check.enable = true;
          settings = {
            settings = {
              deadnix = {
                edit = true;
                noLambdaArg = true;
              };
            };
            hooks = {
              statix = {
                enable = true;
              };
              deadnix = {
                enable = true;
              };
            };
          };
        };

        # Provides the formatter for `nix fmt`
        formatter = pkgs.alejandra;
      };

      flake = {
        # Configures the agenix-rekey app under `perSystem`
        agenix-rekey = {
          type = "app";
          program = inputs.agenix-rekey.configure {
            userFlake = self;
            nodes = self.nixosConfigurations;
          };
        };
      };
    };
}
