# add complementary modules inside this directory.
{inputs, ...}: {
  imports = [
    inputs.byos.nixosModules.byosBuilder
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.agenixRekey
    inputs.home-manager.nixosModules.home-manager
    inputs.nh.nixosModules.default
  ];
}
