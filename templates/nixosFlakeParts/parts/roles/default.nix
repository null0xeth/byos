{
  flake.nixosModules = {
    roles = {
      imports = [./nixos];
    };
  };
}
