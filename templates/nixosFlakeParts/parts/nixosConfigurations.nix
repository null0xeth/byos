{
  withSystem,
  inputs,
  self,
  ...
}: {
  flake = {
    nixosConfigurations = {
      # TODO: change this to your hostname.
      YOUR-HOSTNAME = withSystem "x86_64-linux" ({inputs', ...}:
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs inputs';
          };
          modules = [
            inputs.byos.nixosModules.byosBuilder
            self.nixosModules.roles
            ../hosts
            ../users
          ];
        });
    };
  };
}
