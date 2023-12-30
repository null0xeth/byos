{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.modules.hardware.extras;
in {
  imports = [./submodules/lm_sensors.nix ./submodules/thunderbolt.nix];
  options.modules.hardware.extras = {
    enable = mkEnableOption "enable the extra hardware profile";
    settings = {
      sensors = {
        enable = mkEnableOption "enable the default system sensor profile";
      };
      thunderbolt = {
        enable = mkEnableOption "enable the thunderbolt profile";
      };
      logitech = {
        enable = mkEnableOption "enable the logitech mice profile";
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      sub-modules.hardware.optional = {
        inherit (cfg.settings) sensors thunderbolt;
        # sensors.enable = cfg.settings.sensors.enable;
        # thunderbolt.enable = cfg.settings.thunderbolt.enable;
      };
    }
    (mkIf cfg.settings.logitech.enable {
      hardware = {
        logitech.wireless = {
          enable = true;
          enableGraphical = true;
        };
      };

      services.ratbagd.enable = true;

      services.udev.extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0666"
      '';
    })
  ]);
}
