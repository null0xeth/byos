{
  flake.nixosModules = {
    roles = {
      imports = [./roles/nixos/workstation/intel/poc.nix];
    };
  };
}
