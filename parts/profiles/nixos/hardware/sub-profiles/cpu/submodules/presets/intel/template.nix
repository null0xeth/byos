{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  filterfunc = set: builtins.head (builtins.attrNames (lib.filterAttrs (n: _: set.${n}.enable) set));
  cfg = config.hardware-presets.cpu.intel.${filterfunc config.hardware-presets.cpu.intel};
  cpuSpecs = cfg.cpu;
in {
  options.hardware-presets.cpu.intel = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        enable = mkEnableOption "the base hardware profile";
        name = mkOption {
          type = types.str;
          description = mdDoc "The slug used to refer to this preset";
          default = "default-intel-preset";
        };
        cpu = mkOption {
          type = types.submodule {
            options = {
              brand = mkOption {
                type = types.enum ["intel"];
                description = mdDoc "The manufacturer of your CPU";
                default = "intel";
              };
              generation = mkOption {
                type = types.int;
                description = mdDoc "The generation of your CPU (intel only)";
                default = 0;
              };
              sub-type = mkOption {
                type = types.enum ["mobile" "desktop"];
                description = mdDoc "The type of CPU installed [desktop|mobile]";
                default = "mobile";
              };
            };
          };
        };
        settings = mkOption {
          type = types.submodule {
            options = {
              graphics = mkOption {
                type = types.submodule {
                  options = {
                    enable = mkEnableOption "enable intel integrated graphics";
                    drivers = mkOption {
                      type = types.enum ["modesetting" "intel"];
                      description = mdDoc "The xserver driver to use for Hw acceleratiion";
                      default = "modesetting";
                    };
                    dri = mkOption {
                      type = types.submodule {
                        options = {
                          enable = mkEnableOption "dri support for the graphical backend";
                          settings = mkOption {
                            type = types.enum ["iris" "uxa" "sna"];
                            description = mdDoc "Configuration for /dev/dri/*";
                            default = "iris"; # from 8th gen and up
                          };
                        };
                      };
                    };
                    mesa = mkOption {
                      type = types.submodule {
                        options = {
                          enable = mkEnableOption "the mesa drivers for OpenGL";
                        };
                      };
                    };
                  };
                };
              };
              kernel = mkOption {
                type = types.submodule {
                  options = {
                    gen-profile = mkOption {
                      type = types.submodule {
                        options = {
                          enable = mkEnableOption "apply the best possible settings for this particular CPU";
                        };
                      };
                    };
                    other = mkOption {
                      type = types.submodule {
                        options = {
                          powerstate = mkOption {
                            type = types.submodule {
                              options = {
                                enable = mkEnableOption "Enable intel_pstate";
                              };
                            };
                          };
                        };
                      };
                    };
                  };
                };
              };
              performance = mkOption {
                type = types.submodule {
                  options = {
                    enable = mkEnableOption "default the default CPU performance profile";
                    profile = mkOption {
                      type = types.enum ["performance" "powersave"];
                      default = "performance";
                      description = mdDoc "The Intel CPU frequency profile to use.";
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

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.cpu.generation != 0;
          message = "Please specify the processor generation. It cannot be omitted";
        }
      ];

      boot = {
        kernelModules = ["kvm-intel"];
      };

      hardware = {
        acpilight = mkIf (cpuSpecs.sub-type == "mobile") {
          enable = mkDefault true;
        };
        enableRedistributableFirmware = mkDefault true;
        cpu.intel.updateMicrocode = mkDefault true;
      };

      services.thermald.enable = true;
    }
    (mkIf cfg.settings.graphics.enable {
      boot = {
        kernelModules = ["intel_agp"];
      };

      environment = {
        variables = {
          VDPAU_DRIVER = mkIf config.hardware.opengl.enable (mkDefault "va_gl");
        };
        systemPackages = with pkgs; [libglvnd ffmpeg-full libva-utils];
      };

      hardware = {
        opengl = {
          enable = true;
          package = (mkIf cfg.settings.graphics.mesa.enable) pkgs.mesa.drivers;
          package32 = (mkIf cfg.settings.graphics.mesa.enable) pkgs.mesa.drivers;
          driSupport = cfg.settings.graphics.dri.enable;
          driSupport32Bit = cfg.settings.graphics.dri.enable;
          setLdLibraryPath = true;
          extraPackages = with pkgs; [
            (
              if (strings.versionOlder (versions.majorMinor trivial.version) "23.11")
              then vaapiIntel
              else intel-vaapi-driver
            )
            libvdpau-va-gl
            intel-media-driver
            intel-compute-runtime
          ];
        };
      };

      services.xserver.videoDrivers = ["${cfg.settings.graphics.drivers}"];
    })
    (mkIf (cfg.settings.graphics.dri.enable && (cpuSpecs.generation >= 8)) {
      services.xserver.deviceSection = ''
        Option "DRI" "iris"
        Option "TearFree" "false"
        Option "TripleBuffer" "false"
        Option "SwapBuffersWait" "false"
      '';
    })
    (mkIf (cfg.settings.graphics.dri.enable && (cpuSpecs.generation < 8)) {
      services.xserver.deviceSection = ''
        Option "DRI" "${cfg.settings.graphics.dri.settings}"
        Option "TearFree" "false"
        Option "TripleBuffer" "false"
        Option "SwapBuffersWait" "false"
      '';
    })
    (mkIf cfg.settings.kernel.gen-profile.enable (mkMerge [
      (mkIf ((cpuSpecs.generation
          >= 12)
        && (cpuSpecs.sub-type == "mobile")) {
          boot = {
            initrd.kernelModules = ["i915"];
            kernelParams = [
              "i915.enable_guc=3"
              "i915.enable_psr=0"
              "i915.enable_fbc=1"
              "video=SVIDEO-1:d"
            ];
          };
        })
      (mkIf ((cpuSpecs.generation
          >= 12)
        && (cpuSpecs.sub-type == "desktop")) {
          boot = {
            initrd.kernelModules = ["i915"];
            kernelParams = [
              "i915.enable_guc=2"
              "i915.enable_psr=0"
              "i915.enable_fbc=1"
              "video=SVIDEO-1:d"
            ];
          };
        })
      (mkIf ((cpuSpecs.generation
          >= 9)
        && (cpuSpecs.generation < 12)) {
          boot = {
            initrd.kernelModules = ["i915"];
            kernelParams = [
              "i915.enable_guc=2"
              "i915.enable_psr=0"
              "i915.enable_fbc=1"
              "video=SVIDEO-1:d"
            ];
          };
        })
      (mkIf (cpuSpecs.generation
        == 7) {
        boot = {
          initrd.kernelModules = ["i915"];
          kernelParams = [
            "i915.enable_dc=0"
            "i915.enable_fbc=1"
            "i915.enable_psr=2"
            "intel_idle.max_cstate=1"
            "video=SVIDEO-1:d"
          ];
        };
      })
      (mkIf (cpuSpecs.generation
        == 2) {
        boot = {
          initrd.kernelModules = ["i915"];
          kernelParams = [
            "i915.enable_rc6=7"
          ];
        };
      })
    ]))
    (mkIf (cfg.settings.kernel.other.powerstate.enable
      && (cpuSpecs.generation >= 2)) {
      boot = {
        kernelParams = ["intel_pstate=active"];
      };
    })
    (mkIf cfg.settings.performance.enable {
      powerManagement.cpuFreqGovernor = mkDefault cfg.settings.performance.profile;
    })
  ]);
}
