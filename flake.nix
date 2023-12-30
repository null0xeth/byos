{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix.url = "github:nixos/nix";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    systems.url = "github:nix-systems/default";
    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
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
        };

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

        formatter = pkgs.alejandra;
      };

      flake = {
        templates = {
          default = {
            path = ./templates/nixosFlakeParts;
            description = ''
              A minimal flake using flake-parts.
            '';
          };
        };
      };
    };
}
