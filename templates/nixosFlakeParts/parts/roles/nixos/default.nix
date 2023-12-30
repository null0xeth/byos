{
  flake.nixosModules = {
    roles = {
      imports = [./workstation/intel/poc.nix];
    };
  };
}
