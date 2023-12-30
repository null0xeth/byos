{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.sub-modules.hardware.bluetooth;
in {
  options.sub-modules.hardware.bluetooth = {
    enable = mkEnableOption "bluetooth";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      blueberry # bluetooth tray
      bluez # dependency of blueberry
      bluez-tools # dependency of blueberry
      gnome.gnome-bluetooth_1_0 # dependency of blueberry
      bluetuith # bluetooth TUI
      #cowsay
    ];

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        Experimental = true;
        KernelExperimental = true;
      };
    };
  };
}
