{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf mdDoc;
  cfg = config.modules.hardware.cpu;
  slug = "${cfg.settings.cpuType}-${cfg.settings.sub-type}-${builtins.toString cfg.settings.generation}th";
in {
  imports = [./submodules];
  options.modules.hardware.cpu = {
    enable = mkEnableOption "enable the default CPU profile";
    settings = {
      cpuType = mkOption {
        type = types.enum ["intel" "amd"];
        default = "intel";
        description = "Please select the type of CPU you have (intel/amd)";
      };
      generation = mkOption {
        # cpu generation
        type = types.int;
        default = 0;
        description = "Specify the CPU generation you have (intel only)";
      };
      sub-type = mkOption {
        type = types.enum ["mobile" "desktop"];
        description = mdDoc "The type of CPU installed [desktop|mobile]";
        default = "mobile";
      };
    };
  };
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.generation != 0;
        message = "Please specify the processor generation. It cannot be omitted";
      }
    ];
    hardware-cpu-presets.${slug} = {
      enable = true;
    };
  };
}
