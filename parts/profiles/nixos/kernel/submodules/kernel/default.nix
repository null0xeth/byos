{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.kernel.general;
in {
  options.modules.kernel.general = {
    enable = mkEnableOption "the general kernel configuration module";
    useLatest = mkEnableOption "the latest kernel packages";
    kernelPackages = mkOption {
      type = types.nullOr types.raw;
      description = "If `useLatest` is disabled, specify the packages here";
      default = null;
    };
    kernelModules = mkOption {
      type = types.nullOr (types.listOf types.str);
      description = "Kernel modules to always be installed";
      default = null;
    };
    kernelParams = {
      useDefaults = mkEnableOption "the default kernel parameters";
      customParams = mkOption {
        type = types.nullOr (types.listOf types.str);
        description = "Kernel parameters";
        default = null;
      };
    };
    initrd = {
      systemd = {
        enable = mkEnableOption "systemd in initrd";
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

  config = mkIf cfg.enable (mkMerge [
    ##################################
    ##  --------------------------  ##
    ##  BASIC KERNEL CONFIGURATION  ##
    ##  --------------------------  ##
    ##################################
    ## KERNEL PACKAGES:
    #  ~> When NOT using the latest kernel packages:
    (mkIf (!cfg.useLatest) {
      assertions = [
        {
          assertion = cfg.kernelPackages != null;
          message = "You disabled `useLatest`. Please specify which kernelPackages to use.";
        }
      ];

      boot = {
        kernelPackages = mkDefault cfg.kernelPackages;
      };
    })
    #  ~> When using the latest kernel packages:
    (mkIf cfg.useLatest {
      boot = {
        kernelPackages = mkDefault pkgs.linuxPackages_latest;
      };
    })
    ## KERNEL PARAMS:
    #  ~> When NOT using the default kernel params:
    (mkIf (!cfg.kernelParams.useDefaults) {
      assertions = [
        {
          assertion = cfg.kernelParams.customParams != null;
          message = "You have disabled the default kernelParams. Please specify which kernelParams to use.";
        }
      ];

      boot = {
        kernelParams = cfg.kernelParams.customParams;
      };
    })
    #  ~> When using the default kernel params:
    (mkIf cfg.kernelParams.useDefaults {
      boot = {
        kernelParams = [
          "pti=auto" # on | off -> auto means kernel will automatically decide the pti state
          "noresume" # disables resume and restores original swap space
          "rd.systemd.show_status=auto" # disable systemd status messages -> rd prefix means systemd-udev will be used instead of initrd
          "rd.udev.log_level=3"
          "vt.global_cursor_default=0" # disable the cursor in vt to get a black screen during intermissions
        ];
      };
    })
    ##  KERNEL MODULES:
    #   ~> Override defaults with kernel modules derived from `hardware-config.nix`:
    (mkIf (cfg.kernelModules != null) {
      boot.kernelModules = cfg.kernelModules;
    })
    #
    ############################
    ##  --------------------  ##
    ##  INITRD CONFIGURATION  ##
    ##  --------------------  ##
    ############################
    ##  SYSTEMD:
    #   ~> Enable systemd in initrd:
    (mkIf cfg.initrd.systemd.enable {
      boot = {
        initrd = {
          verbose = false;
          systemd = {
            enable = true;
          };
        };
      };
    })
    ##  INITRD KERNEL MODULES:
    (mkIf (cfg.initrd.kernelModules != null) {
      boot.initrd.kernelModules = cfg.initrd.kernelModules;
    })
    (mkIf (cfg.initrd.availableKernelModules != null) {
      boot.initrd.availableKernelModules = cfg.initrd.availableKernelModules;
    })
    #############################
    ##  ---------------------  ##
    ##  GENERAL CONFIGURATION  ##
    ##  ---------------------  ##
    #############################
    {
      boot.kernel = {
        sysctl = {
          "vm.swappiness" = 10;
          "vm.dirty_bytes" = 1024 * 1024 * 512;
          "vm.dirty_background_bytes" = 1024 * 1024 * 32;
        };
      };
    }
  ]);
}
