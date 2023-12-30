{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mdDoc types mkIf;
  filterfunc = set: builtins.head (builtins.attrNames (lib.filterAttrs (n: _: set.${n}.enable) set));
  cfg = config.profiles.hardware.preset.${filterfunc config.profiles.hardware.preset};

  enableModule = lib.types.submodule {
    options = {
      enable = mkEnableOption "";
    };
  };
in {
  imports = [
    ./cpu
    ./core
    ./extras
  ];

  options.profiles.hardware = {
    preset = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "the base hardware profile";
          name = mkOption {
            type = types.str;
            description = mdDoc "The slug used to refer to this profile";
            default = "default-hardware-template";
          };
          profile = mkOption {
            type = types.submodule {
              options = {
                cpu = mkOption {
                  type = types.submodule {
                    options = {
                      brand = mkOption {
                        type = types.enum ["intel" "amd"];
                        description = mdDoc "The manufacturer of your CPU";
                        default = "intel";
                      };
                      generation = mkOption {
                        type = types.nullOr types.int;
                        description = mdDoc "The generation of your CPU (intel only)";
                        default = null;
                      };
                      sub-type = mkOption {
                        type = types.enum ["mobile" "desktop"];
                        description = mdDoc "The type of CPU installed [desktop|mobile]";
                        default = "mobile";
                      };
                    };
                  };
                };
                gpu = mkOption {
                  type = types.submodule {
                    options = {
                      type = mkOption {
                        type = types.enum ["cpu" "dedicated" "none"];
                        description = mdDoc "The type of GPU you have [cpu | dedicated | none]";
                        default = "cpu";
                      };
                    };
                  };
                };
              };
            };
          };

          core = mkOption {
            type = types.submodule {
              options = {
                audio = mkOption {
                  type = enableModule;
                };
                bluetooth = mkOption {
                  type = enableModule;
                };
                storage = mkOption {
                  type = enableModule;
                };
              };
            };
          };

          optionals = mkOption {
            type = types.submodule {
              options = {
                thunderbolt = mkOption {
                  type = enableModule;
                };
                sensors = mkOption {
                  type = enableModule;
                };
                peripherals = mkOption {
                  type = types.submodule {
                    options = {
                      logitech = mkOption {
                        type = enableModule;
                      };
                    };
                  };
                };
              };
            };
          };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    modules.hardware = {
      core = {
        enable = cfg.core.audio.enable || cfg.core.bluetooth.enable || cfg.core.storage.enable;
        settings = {
          audio.enable = cfg.core.audio.enable;
          bluetooth.enable = cfg.core.bluetooth.enable;
          storage.enable = cfg.core.storage.enable;
        };
      };

      cpu = {
        enable = true;
        settings = {
          cpuType = cfg.profile.cpu.brand;
          generation = mkIf (cfg.profile.cpu.brand == "intel" && cfg.profile.cpu.generation != null) cfg.profile.cpu.generation;
          inherit (cfg.profile.cpu) sub-type;
        };
      };

      extras = {
        enable = cfg.optionals.thunderbolt.enable || cfg.optionals.sensors.enable || cfg.optionals.peripherals.logitech.enable;
        settings = {
          sensors.enable = true;
          thunderbolt.enable = true;
          logitech.enable = true;
        };
      };
    };
  };
}
