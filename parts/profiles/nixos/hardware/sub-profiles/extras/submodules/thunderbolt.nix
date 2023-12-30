{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.sub-modules.hardware.optional.thunderbolt;
in {
  options.sub-modules.hardware.optional.thunderbolt = {
    enable = mkEnableOption "Whether to enable the thunderbolt module";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [thunderbolt acpi acpid];

    boot = {
      kernelModules = ["thunderbolt"];
      kernelPatches = [
        {
          name = "thunderbolt";
          patch = null;
          extraConfig = ''
            HOTPLUG_PCI y
            HOTPLUG_PCI_ACPI y
          '';
        }
      ];
    };

    boot.initrd = {
      availableKernelModules = ["thunderbolt"];
      kernelModules = ["thunderbolt"];
    };

    services = {
      acpid.enable = true;
      hardware.bolt.enable = true;
      udev.extraRules = ''
        ACTION==""add"", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
      '';
    };
  };
}
