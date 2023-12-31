{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  filterfunc = set: builtins.head (builtins.attrNames (lib.filterAttrs (n: v: set.${n}.enable) set));
  cfg = config.profiles.kernel.preset.${filterfunc config.profiles.kernel.preset};

  enableModule = lib.types.submodule {
    options = {
      enable = mkEnableOption "";
    };
  };
  nestedEnableModule = subName:
    lib.types.submodule {
      options = {
        ${subName} = mkOption {
          type = lib.types.submodule {
            options = {
              enable = mkEnableOption "";
            };
          };
        };
      };
    };

  profileTemplate = {
    name,
    config,
    ...
  }: {
    options = {
      name = mkOption {
        type = types.str;
        default = "nakedTemplate";
        description = mdDoc "Capybara";
      };

      enable = mkEnableOption "the default kernel profile template";
      general = mkOption {
        type = types.submodule {
          options = {
            enable = mkEnableOption (mdDoc "the general kernel configuration module");
            useLatest = mkEnableOption "the latest kernel packages";
            kernelPackages = mkOption {
              type = types.nullOr types.raw;
              description = "If `useLatest` is disabled, specify the packages here";
              default = null;
            };
            kernelModules = mkOption {
              type = types.nullOr (types.listOf types.str);
              description = "Kernel modules to be installed";
              default = null;
            };
            kernelParams = mkOption {
              type = types.submodule {
                options = {
                  useDefaults = mkEnableOption "the default kernel parameters";
                  customParams = mkOption {
                    type = types.nullOr (types.listOf types.str);
                    description = "Kernel parameters";
                    default = null;
                  };
                };
              };
            };
            initrd = mkOption {
              type = types.submodule {
                options = {
                  systemd = mkOption {
                    type = enableModule;
                  };
                  kernelModules = mkOption {
                    type = types.nullOr (types.listOf types.str);
                    description = "Kernel modules to always be installed";
                    default = null;
                  };
                  availableKernelModules = mkOption {
                    type = types.nullOr (types.listOf types.str);
                    description = "Kernel modules to be installed";
                    default = null;
                  };
                };
              };
            };
          };
        };
      };

      tweaks = mkOption {
        type = types.submodule {
          options = {
            networking = mkOption {
              type = enableModule;
            };
            hardening = mkOption {
              type = enableModule;
            };
            failsaves = mkOption {
              type = enableModule;
            };
            clean = mkOption {
              type = enableModule;
            };
          };
        };
      };

      boot = mkOption {
        type = types.submodule {
          options = {
            enable = mkEnableOption "blabla";
            general = mkOption {
              type = nestedEnableModule "silent";
            };
            tmpfs = mkOption {
              type = types.submodule {
                options = {
                  enable = mkEnableOption "the temporary filesystem";
                  size = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                  };
                };
              };
            };
            loader = mkOption {
              type = types.submodule {
                options = {
                  systemd = mkOption {
                    type = types.submodule {
                      options = {
                        enable = mkEnableOption "systemd boot for this system";
                        configurationLimit = mkOption {
                          type = types.nullOr types.int;
                          default = 5;
                          description = mdDoc "the maximum number of nixos generations kept on this system";
                        };
                      };
                    };
                  };
                  settings = mkOption {
                    type = types.submodule {
                      options = {
                        efiSupport = mkOption {
                          type = enableModule;
                        };
                        timeout = mkOption {
                          type = types.int;
                          default = 3;
                          description = mdDoc "the maximum allowed time in seconds to time out kernel operations";
                        };
                        copyToTmpfs = mkOption {
                          type = enableModule;
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };

      optionals = mkOption {
        type = nestedEnableModule "ricemyttydotcom";
      };
    };
  };
in {
  imports = [./submodules];

  options.profiles.kernel = {
    preset = mkOption {
      type = types.attrsOf (types.submodule profileTemplate);
      default = {};
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      modules.kernel = {
        inherit (cfg) boot general tweaks;
      };
    }
    (mkIf cfg.optionals.ricemyttydotcom.enable {
      boot = {
        kernelParams = [
          # RiceMyTTY.com/zerofucksgiven
          "vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166"
          "vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173"
          "vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"
        ];
      };

      console = {
        font = "Lat2-Terminus16";
        earlySetup = true;
        useXkbConfig = true;
        packages = with pkgs; [terminus_font];
      };
    })
  ]);
}
