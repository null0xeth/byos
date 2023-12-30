{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.nixos-modules.system.firmware;
in {
  options.nixos-modules.system.firmware = {
    enable = mkEnableOption "enable the firmware module";

    automatic-updates = {
      enable = mkEnableOption "enable automatic firmware updates";
    };

    packages = mkOption {
      type = with types; listOf package;
      default = [];
      description = mdDoc "Firmware packages to install";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ## Default configuration:
    {
      hardware = {
        enableAllFirmware = mkDefault true;
        enableRedistributableFirmware = mkDefault true;
        firmware = cfg.packages;
      };
      services.sysprof.enable = true; # system profiler
    }

    ## Additional configuration:
    (mkIf cfg.automatic-updates.enable {
      services.fwupd = {
        enable = true; # update firmware
        daemonSettings.EspLocation = config.boot.loader.efi.efiSysMountPoint;
      };
    })
  ]);
}
