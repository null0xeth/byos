{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.kernel.boot;
in {
  options.modules.kernel.boot = {
    enable = mkEnableOption "the kernel boot configuration model";

    general = {
      silent = {
        enable = mkEnableOption "completely silence the kernel messages in TTY";
      };
    };

    tmpfs = {
      enable = mkEnableOption "the temporary filesystem";
      size = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = mdDoc "the numeric representation of the percentage of ram to allocate to tmpfs [eg. 75, 50, ..]";
      };
    };

    loader = {
      systemd = {
        enable = mkEnableOption "systemd boot for this system";
        configurationLimit = mkOption {
          type = types.nullOr types.int;
          default = 5;
          description = mdDoc "the maximum number of nixos generations kept on this system";
        };
      };
      settings = {
        efiSupport = {
          enable = mkEnableOption "allow EFI variables to be modified";
        };
        timeout = mkOption {
          type = types.int;
          default = 3;
          description = mdDoc "the maximum allowed time in seconds to time out kernel operations";
        };
        copyToTmpfs = {
          enable = mkEnableOption "copying the kernel of each nixos generation to tmpfs";
        };
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [
    #############################
    ##  ---------------------  ##
    ##  GENERAL CONFIGURATION  ##
    ##  ---------------------  ##
    #############################
    ## TTY CONSOLE:
    (mkIf cfg.general.silent.enable {
      boot.consoleLogLevel = mkDefault 0;
      boot.kernelParams = ["quiet"];
    })
    (mkIf (!cfg.general.silent.enable) {
      boot.consoleLogLevel = mkDefault 3;
    })

    ###########################
    ##  -------------------  ##
    ##  TMPFS CONFIGURATION  ##
    ##  -------------------  ##
    ###########################
    ## CONFIGURING BOOT:
    #  ~> if tmpfs is enabled:
    (mkIf cfg.tmpfs.enable {
      assertions = mkMerge [
        {
          assertion = config.kernel-modules.patches.failsaves;
          message = "Really mfer? Are you going to run tmpfs without failsaves to save ur ass?";
        }
        {
          assertion = cfg.tmpfs.size != null;
          message = "You have enabled `Tmpfs`, but omitted `tmpfs size`";
        }
        {
          assertion = cfg.tmpfs.size >= 50;
          message = "Please increase the allocated amount of RAM to tmpfs. Sub 50% is not acceptable";
        }
      ];

      warnings =
        if cfg.tmpfs.size < 70
        then [
          ''            Are you absolutely sure that you want to use less than 70% of your RAM for tmpfs?
                             Please reconsider before proceeding''
        ]
        else [];

      boot = {
        tmp = let
          convertedSize = "${builtins.toString cfg.tmpfs.size}%";
        in {
          useTmpfs = mkDefault true;
          cleanOnBoot = mkDefault false;
          tmpfsSize = mkDefault convertedSize;
        };
      };
    })
    #  ~> if tmpfs is enabled:
    (mkIf (!cfg.tmpfs.enable) {
      boot = {
        tmp = {
          useTmpfs = mkDefault false;
          cleanOnBoot = mkDefault true;
        };
      };
    })
    #################################
    ##  -------------------------  ##
    ##  BOOT LOADER CONFIGURATION  ##
    ##  -------------------------  ##
    #################################
    ## GENERAL SETTINGS:
    {
      # TODO: move this
      hardware.ksm.enable = true;
      boot = {
        loader = {
          timeout = mkForce cfg.loader.settings.timeout;
          efi = {
            canTouchEfiVariables = cfg.loader.settings.efiSupport.enable; # modify EFI variables
          };
          generationsDir = {
            copyKernels = mkForce cfg.loader.settings.copyToTmpfs.enable;
          };
        };
      };
    }

    ## SYSTEMD BOOT:
    #  ~> if systemd boot is enabled:
    (mkIf cfg.loader.systemd.enable {
      #environment.systemPackages = with pkgs; [poop lolcat cowsay];
      boot = {
        loader = {
          systemd-boot = {
            enable = true;
            inherit (cfg.loader.systemd) configurationLimit;
          };
        };
      };
    })
  ]);
}
