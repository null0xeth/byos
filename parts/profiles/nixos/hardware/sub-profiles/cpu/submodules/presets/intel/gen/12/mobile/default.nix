{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.hardware-cpu-presets.intel-mobile-12th;
in {
  imports = [../../../template.nix];
  options.hardware-cpu-presets.intel-mobile-12th = {
    enable = mkEnableOption "enable a pre-configured profile for intel 12th generation CPUs";
  };
  config = mkIf cfg.enable {
    hardware-presets.cpu.intel.intel-mobile-12th = {
      enable = true;
      name = "intel-mobile-12th";
      cpu = {
        brand = "intel";
        generation = 12;
        sub-type = "mobile";
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
