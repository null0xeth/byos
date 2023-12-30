# add complementary home-manager modules to this directory
{inputs, ...}: {
  imports = [
    inputs.nix-index-database.hmModules.nix-index
  ];
}
