{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.hardware-cpu-presets.intel-desktop-11th;
in {
  imports = [../../../template.nix];
  options.hardware-cpu-presets.intel-desktop-11th = {
    enable = mkEnableOption "enable a pre-configured profile for intel 11th generation CPUs";
  };
  config = mkIf cfg.enable {
    hardware-presets.cpu.intel.intel-desktop-11th = {
      enable = true;
      name = "intel-desktop-11th";
      cpu = {
        brand = "intel";
        generation = 11;
        sub-type = "desktop";
      };
      settings = {
        graphics = {
          enable = true;
          drivers = "modesetting";
          dri = {
            enable = true;
            settings = "iris";
          };
          mesa = {
            enable = true;
          };
        };
        kernel = {
          gen-profile = {
            enable = true;
          };
          other = {
            powerstate = {
              enable = true;
            };
          };
        };
        performance = {
          enable = true;
          profile = "performance";
        };
      };
    };
  };
}
