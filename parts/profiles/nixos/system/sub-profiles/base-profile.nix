{
  config,
  lib,
  ...
}:
with lib; let
  filterfunc = set: builtins.head (builtins.attrNames (lib.filterAttrs (n: _: set.${n}.enable) set));
  cfg = config.profiles.system.preset.${filterfunc config.profiles.system.preset};

  enableModule = lib.types.submodule {
    options = {
      enable = mkEnableOption "";
    };
  };
in {
  imports = [
    ./utils
    ./firmware
    ./networking
    ./submodules
  ];

  options.profiles.system = {
    preset = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "the default system profile template";
          name = mkOption {
            type = types.str;
            description = mdDoc "The slug used to refer to this profile";
            default = "default-hardware-template";
          };
          profile = mkOption {
            type = types.submodule {
              options = {
                firmware = mkOption {
                  type = types.submodule {
                    options = {
                      enable = mkEnableOption "the firmware configuration module";
                      packages = mkOption {
                        type = with types; listOf package;
                        default = [];
                        description = mdDoc "Firmware packages to be installed";
                      };
                    };
                  };
                };
              };
            };
          };
          fonts = mkOption {
            type = types.submodule {
              options = {
                enable = mkEnableOption "the font configuration module";
                packages = mkOption {
                  type = with types; listOf package;
                  default = [];
                  description = mdDoc "Font packages to install";
                };
                defaults = mkOption {
                  type = types.submodule {
                    options = {
                      serif = mkOption {
                        type = with types; listOf str;
                        default = [];
                      };
                      sansSerif = mkOption {
                        type = with types; listOf str;
                        default = [];
                      };
                      monospace = mkOption {
                        type = with types; listOf str;
                        default = [];
                      };
                      emoji = mkOption {
                        type = with types; listOf str;
                        default = [];
                      };
                    };
                  };
                };
              };
            };
          };

          sysutils = mkOption {
            type = types.submodule {
              options = {
                enable = mkEnableOption "the system utilities module";
                tools = mkOption {
                  type = types.submodule {
                    options = {
                      common = mkOption {
                        type = enableModule;
                      };
                      direnv = mkOption {
                        type = enableModule;
                      };
                      envfs = mkOption {
                        type = enableModule;
                      };
                      ld = mkOption {
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

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.profile.firmware.enable {
      nixos-modules.system.firmware = {
        inherit (cfg.profile.firmware) enable packages;
      };
    })

    (mkIf cfg.fonts.enable {
      fonts = {
        enableDefaultPackages = true;
        inherit (cfg.fonts) packages;
        fontconfig.defaultFonts = cfg.fonts.defaults;
      };
    })

    (mkIf cfg.sysutils.enable {
      nixos-modules.sysutils = {
        inherit (cfg.sysutils) enable tools;
      };
    })
  ]);
}
