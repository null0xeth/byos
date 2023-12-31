{moduleWithSystem, config, ...}: {
flake.nixosModules.byosBuilder = moduleWithSystem (
    perSystem @ {self'}: nixos @ {
      lib,
      ...
    }:
with lib; let
  filterfunc = set: builtins.head (builtins.attrNames (lib.filterAttrs (n: _: set.${n}.enable) set));
  cfg = config.byosBuilder.presets.${filterfunc config.byosBuilder.presets};

  enableModule = lib.types.submodule {
    options = {
      enable = mkEnableOption "";
    };
  };

  # QuickNav ##:
  hwCfg = cfg.builder.hardware;
  kernCfg = cfg.builder.kernel;
  fxCfg = cfg.builder.graphical;
  sysCfg = cfg.builder.system;
  secCfg = cfg.builder.security;
in {
  imports = [
    ./profiles/nixos/kernel
    ./profiles/nixos/system
    ./profiles/nixos/hardware
    ./profiles/nixos/security
    ./profiles/nixos/graphical
  ];

  options.byosBuilder = {
    presets = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        enable = mkEnableOption "the preset builder";
        name = mkOption {
          type = types.str;
          description = mdDoc "The slug used to refer to preset";
          default = "bobTheBuilder";
        };
        builder = mkOption {
          type = types.submodule {
            options = {
              networking = mkOption {
                type = types.submodule {
                  options = {
                    hostName = mkOption {
                      type = types.str;
                      description = mdDoc "The hostname of the to-be configured system";
                      default = "honkmaster-007";
                    };
                    extraHosts = mkOption {
                      type = types.nullOr types.lines;
                      description = mdDoc "Extra hosts to add to /etc/hosts";
                    };
                  };
                };
              };
              fromHardwareConfig = mkOption {
                type = types.submodule {
                  options = {
                    _completed = mkOption {
                      readOnly = true;
                      default = (cfg.builder.fromHardwareConfig.kernelModules != null) && (cfg.builder.fromHardwareConfig.initrd.availableKernelModules != null);
                    };
                    kernelModules = mkOption {
                      type = types.nullOr (types.listOf types.str);
                      description = mdDoc "add kernelModules from ur Hardware-config.nix";
                    };
                    initrd = mkOption {
                      type = types.submodule {
                        options = {
                          availableKernelModules = mkOption {
                            type = types.nullOr (types.listOf types.str);
                            description = mdDoc "add initrd kernelModules from ur Hardware-config.nix";
                          };
                        };
                      };
                    };
                    #fileSystems = {
                    # .. add later
                    #};
                  };
                };
              };

              hardware = mkOption {
                type = types.submodule {
                  options = {
                    basics = mkOption {
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
                            # TODO: more details related to ssd
                          };
                        };
                      };
                    };
                    cpu = mkOption {
                      type = types.submodule {
                        options = {
                          brand = mkOption {
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
                          useForGraphics = mkEnableOption "use the integrated graphics of the CPU";
                        };
                      };
                    };

                    functionality = mkOption {
                      type = types.submodule {
                        options = {
                          thunderbolt = mkOption {
                            type = enableModule;
                          };
                          sensors = mkOption {
                            type = enableModule;
                          };
                          logitech = mkOption {
                            type = enableModule;
                          };
                        };
                      };
                    };
                  };
                };
              };

              kernel = mkOption {
                type = types.submodule {
                  options = {
                    settings = mkOption {
                      type = types.submodule {
                        options = {
                          useLatest = mkEnableOption "the latest kernel packages";
                          kernelPackages = mkOption {
                            type = types.nullOr types.raw;
                            description = "If `useLatest` is disabled, specify the packages here";
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
                          settings = mkOption {
                            type = types.submodule {
                              options = {
                                general = mkOption {
                                  type = types.submodule {
                                    options = {
                                      silent = mkEnableOption "silence the console logs";
                                    };
                                  };
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
                                      systemd-boot = mkOption {
                                        type = types.submodule {
                                          options = {
                                            enable = mkEnableOption "use systemd boot";
                                            configurationLimit = mkOption {
                                              type = types.nullOr types.int;
                                              default = 5;
                                              description = mdDoc "the maximum number of nixos generations kept on this system";
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

                          stages = mkOption {
                            type = types.submodule {
                              options = {
                                stage1 = mkOption {
                                  type = types.submodule {
                                    options = {
                                      initrd = mkOption {
                                        type = types.submodule {
                                          options = {
                                            systemd = mkOption {
                                              type = enableModule; # enable systemd in the first stage of booting.
                                            };
                                            kernelModules = mkOption {
                                              type = types.nullOr (types.listOf types.str);
                                              description = "Kernel modules to always be installed";
                                              default = null;
                                            };
                                            availableKernelModules = mkOption {
                                              type = types.listOf types.str;
                                              description = "Kernel modules to be installed";
                                              default = cfg.builder.fromHardwareConfig.initrd.availableKernelModules;
                                            };
                                          };
                                        };
                                      };
                                    };
                                  };
                                };

                                stage2 = mkOption {
                                  type = types.submodule {
                                    options = {
                                      kernelModules = mkOption {
                                        type = types.listOf types.str;
                                        description = "Kernel modules to be installed";
                                        default = cfg.builder.fromHardwareConfig.kernelModules;
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
                  };
                };
              };

              graphical = mkOption {
                type = types.submodule {
                  options = {
                    settings = mkOption {
                      type = types.submodule {
                        options = {
                          base = mkOption {
                            type = types.enum ["gtk"];
                            description = mdDoc "The base layer used for rendering the system's gui";
                            default = "gtk";
                          };
                          dbus = mkOption {
                            type = enableModule;
                          };
                        };
                      };
                    };

                    xserver = mkOption {
                      type = types.submodule {
                        options = {
                          base = mkOption {
                            type = types.submodule {
                              options = {
                                enable = mkEnableOption "xserver";
                                exportConfiguration = mkOption {
                                  type = enableModule;
                                };
                                hyperlandSupport = mkOption {
                                  type = enableModule;
                                };
                                libinput = mkOption {
                                  type = enableModule;
                                };
                              };
                            };
                          };
                          desktopManager = mkOption {
                            type = types.submodule {
                              options = {
                                enable = mkEnableOption "enable the desktopmanager module";
                                active = mkOption {
                                  type = types.enum ["gnome" "none"];
                                  default = "none";
                                };
                              };
                            };
                          };
                          displayManager = mkOption {
                            type = types.submodule {
                              options = {
                                enable = mkEnableOption "enable the displaymanager module";
                                active = mkOption {
                                  type = types.enum ["gdm" "none"];
                                  default = "none";
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

              system = mkOption {
                type = types.submodule {
                  options = {
                    firmware = mkOption {
                      type = types.submodule {
                        options = {
                          enable = mkEnableOption "the firmware configuration module";
                          packages = mkOption {
                            type = with types; nullOr (listOf package);
                            description = mdDoc "Firmware packages to be installed";
                            default = null;
                          };
                        };
                      };
                    };

                    fonts = mkOption {
                      type = types.submodule {
                        options = {
                          enable = mkEnableOption "the font configuration module";
                          packages = mkOption {
                            type = with types; nullOr (listOf package);
                            description = mdDoc "Font packages to install";
                          };
                          defaults = mkOption {
                            type = types.submodule {
                              options = {
                                serif = mkOption {
                                  type = with types; nullOr (listOf str);
                                };
                                sansSerif = mkOption {
                                  type = with types; nullOr (listOf str);
                                };
                                monospace = mkOption {
                                  type = with types; nullOr (listOf str);
                                };
                                emoji = mkOption {
                                  type = with types; nullOr (listOf str);
                                };
                              };
                            };
                          };
                        };
                      };
                    };

                    utilities = mkOption {
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
                };
              };

              security = mkOption {
                type = types.submodule {
                  options = {
                    modules = mkOption {
                      type = types.submodule {
                        options = {
                          agenix = mkOption {
                            type = enableModule;
                          };

                          yubikey = mkOption {
                            type = types.submodule {
                              options = {
                                enable = mkEnableOption "support for yubikey mfa";
                                settings = mkOption {
                                  type = types.submodule {
                                    options = {
                                      configuration = mkOption {
                                        type = types.submodule {
                                          options = {
                                            idVendor = mkOption {
                                              type = types.str;
                                              default = null;
                                              description = "Yubikey vendor id";
                                            };
                                            idProduct = mkOption {
                                              type = types.str;
                                              default = null;
                                              description = "Yubikey product id";
                                            };
                                          };
                                        };
                                      };
                                      udev = mkOption {
                                        type = enableModule;
                                      };
                                      touchDetector = mkOption {
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
    # Initial assertions:
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "Preset name cannot be omitted.";
        }
        {
          assertion = cfg.builder.fromHardwareConfig._completed;
          message = "Please fill in all fields under `builder.fromHardwareConfig`";
        }
      ];

      # Networking:
      profiles.networking.preset.${cfg.name} = {
        enable = true;
        hostName = cfg.builder.networking.hostName;
        extraHosts = cfg.builder.networking.extraHosts;
      };

      # Hardware:
      profiles.hardware.preset.${cfg.name} = {
        enable = true;
        name = "${cfg.name}";
        profile = {
          cpu = {
            brand = hwCfg.cpu.brand;
            generation = hwCfg.cpu.generation;
            sub-type = hwCfg.cpu.sub-type;
          };
          # TODO: fix later
          gpu = {
            type = "cpu";
          };
        };
        core = {
          audio.enable = hwCfg.basics.audio.enable;
          bluetooth.enable = hwCfg.basics.bluetooth.enable;
          storage.enable = hwCfg.basics.storage.enable;
        };
        optionals = {
          thunderbolt.enable = hwCfg.functionality.thunderbolt.enable;
          sensors.enable = hwCfg.functionality.sensors.enable;
          peripherals.logitech.enable = hwCfg.functionality.logitech.enable;
        };
      };

      # Kernel:
      profiles.kernel.preset.${cfg.name} = {
        enable = true;
        name = "${cfg.name}";
        general = {
          enable = true;
          useLatest = kernCfg.settings.useLatest;
          kernelPackages = kernCfg.settings.kernelPackages;
          kernelModules = kernCfg.boot.stages.stage2.kernelModules;

          kernelParams = {
            useDefaults = kernCfg.settings.kernelParams.useDefaults;
            customParams = kernCfg.settings.kernelParams.customParams;
          };
          #};
          initrd = {
            systemd.enable = kernCfg.boot.stages.stage1.initrd.systemd.enable;
            kernelModules = kernCfg.boot.stages.stage1.initrd.kernelModules;
            availableKernelModules = kernCfg.boot.stages.stage1.initrd.availableKernelModules;
          };
        };

        tweaks = {
          networking.enable = kernCfg.tweaks.networking.enable;
          hardening.enable = kernCfg.tweaks.hardening.enable;
          failsaves.enable = kernCfg.tweaks.failsaves.enable;
          clean.enable = kernCfg.tweaks.clean.enable;
        };

        boot = {
          enable = true;
          general = {
            silent = {
              enable = kernCfg.boot.settings.general.silent;
            };
          };

          tmpfs = {
            enable = kernCfg.boot.settings.tmpfs.enable;
            size = kernCfg.boot.settings.tmpfs.size;
          };

          loader = {
            systemd = {
              enable = kernCfg.boot.settings.loader.systemd-boot.enable;
              configurationLimit = kernCfg.boot.settings.loader.systemd-boot.configurationLimit;
            };

            settings = {
              timeout = kernCfg.boot.settings.loader.timeout;
              efiSupport.enable = kernCfg.boot.settings.loader.efiSupport.enable;
              copyToTmpfs.enable = kernCfg.boot.settings.loader.copyToTmpfs.enable;
            };
          };
        };
        optionals = {
          ricemyttydotcom = {
            enable = true;
          };
        };
      };

      # Graphical:
      profiles.graphical.preset.${cfg.name} = {
        enable = true;
        name = "${cfg.name}";
        base = fxCfg.settings.base;

        settings = {
          system = {
            dbus = {
              enable = fxCfg.settings.dbus.enable;
            };
            xserver = {
              enable = fxCfg.xserver.base.enable;
            };
          };
          core = {
            desktopManager = {
              enable = fxCfg.xserver.desktopManager.enable;
              active = fxCfg.xserver.desktopManager.active;
            };
            displayManager = {
              enable = fxCfg.xserver.displayManager.enable;
              active = fxCfg.xserver.displayManager.active;
            };
            libinput = {
              enable = fxCfg.xserver.base.libinput.enable;
            };
            extra = {
              hyperlandSupport = {
                enable = fxCfg.xserver.base.hyperlandSupport.enable;
              };
              exportConfiguration = {
                enable = fxCfg.xserver.base.exportConfiguration.enable;
              };
            };
          };
        };
      };

      # System:
      profiles.system.preset.${cfg.name} = {
        enable = true;
        name = "${cfg.name}";
        profile = {
          firmware = {
            enable = sysCfg.firmware.enable;
          };
        };
        fonts = {
          enable = sysCfg.fonts.enable;
          packages = sysCfg.fonts.packages;
          defaults = {
            serif = sysCfg.fonts.defaults.serif;
            sansSerif = sysCfg.fonts.defaults.sansSerif;
            monospace = sysCfg.fonts.defaults.monospace;
            emoji = sysCfg.fonts.defaults.emoji;
          };
        };
        sysutils = {
          enable = sysCfg.utilities.enable;
          tools = {
            common.enable = sysCfg.utilities.tools.common.enable;
            direnv.enable = sysCfg.utilities.tools.direnv.enable;
            envfs.enable = sysCfg.utilities.tools.envfs.enable;
            ld.enable = sysCfg.utilities.tools.ld.enable;
          };
        };
      };

      profiles.security.preset.${cfg.name} = {
        enable = true;
        modules = {
          agenix = {
            enable = secCfg.modules.agenix.enable;
          };
          yubikey = {
            enable = secCfg.modules.yubikey.enable;
            settings = {
              configuration = {
                idVendor = secCfg.modules.yubikey.settings.configuration.idVendor;
                idProduct = secCfg.modules.yubikey.settings.configuration.idProduct;
              };
              udev = {
                enable = secCfg.modules.yubikey.settings.udev.enable;
              };
              touchDetector = {
                enable = secCfg.modules.yubikey.settings.touchDetector.enable;
              };
            };
          };
        };
      };
    }
  ]);
}
);
}
