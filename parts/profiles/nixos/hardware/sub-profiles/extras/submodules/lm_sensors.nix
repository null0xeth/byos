{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.sub-modules.hardware.optional.sensors;
in {
  options.sub-modules.hardware.optional.sensors = {
    enable = mkEnableOption "Whether to enable the hardware sensors module";
  };

  config = mkIf cfg.enable {
    boot.kernelModules = ["coretemp"];

    environment = {
      systemPackages = with pkgs; [psensor lm_sensors];
      etc."sysconfig/lm_sensors".text = ''
        HWMON_MODULES="coretemp"
      '';
    };

    hardware.sensor = {
      iio.enable =
        lib.mkDefault
        true; # Needed for desktop environments to detect/manage display brightness
    };

    #services.thermald.enable = true;
  };
}
