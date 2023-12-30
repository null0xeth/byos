{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.modules.hardware.core;
in {
  imports = [./submodules/audio.nix ./submodules/bluetooth.nix];
  options.modules.hardware.core = {
    enable = mkEnableOption "enable the default hardware configuration";
    settings = {
      audio = {
        enable = mkEnableOption "enable the default audio profile";
      };
      bluetooth = {
        enable = mkEnableOption "enable the default bluetooth profile";
      };
      storage = {
        enable =
          mkEnableOption "enable the default storage configuration profile";
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.settings.storage.enable {
      environment.systemPackages = [pkgs.gparted];
      services.smartd.enable = true; # smart disks
    })
    {
      sub-modules.hardware = {
        audio.enable = cfg.settings.audio.enable;
        bluetooth.enable = cfg.settings.bluetooth.enable;
      };
    }
  ]);
}
