{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  name = "base-intel-12-thunderbolt";
  cfg = config.profiles.hardware-config.${name};
in {
  imports = [
    ../sub-profiles/base-profile.nix
  ];

  options.profiles.hardware-config.${name} = {
    enable =
      mkEnableOption
      "the base hardware profile with a 12th gen Intel CPU and thunderbolt";
  };

  config = mkIf cfg.enable {
    profiles.hardware.preset.${name} = {
      enable = true;
      name = "${name}";
      profile = {
        cpu = {
          brand = "intel";
          generation = 12;
          sub-type = "mobile";
        };
        gpu = {
          type = "cpu";
        };
      };
      core = {
        audio.enable = true;
        bluetooth.enable = true;
        storage.enable = true;
      };
      optionals = {
        thunderbolt.enable = true;
        sensors.enable = true;
        peripherals.logitech.enable = true;
      };
    };
  };
}
