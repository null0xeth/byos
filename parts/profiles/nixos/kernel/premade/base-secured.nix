{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.profiles.kernel-config.baseSecured;
  name = "baseSecured";
in {
  imports = [
    ../sub-profiles/base-profile.nix
  ];

  options.profiles.kernel-config.baseSecured = {
    enable = mkEnableOption (mdDoc "tba");
    settings = mkOption {
      description = mdDoc "tba";
      type = types.submodule {
        options = {
          kernelModules = mkOption {
            type = types.listOf types.str;
            default = [];
            description = mdDoc "tba";
          };
          availableKernelModulesIRD = mkOption {
            type = types.listOf types.str;
            default = [];
            description = mdDoc "tba";
          };
        };
      };
      default = {};
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      profiles.kernel.preset = {
        ${name} = {
          enable = true;
          name = "baseSecured";
          general = {
            enable = true;
            useLatest = true;

            #settings = {
            kernelPackages = [];
            inherit (cfg.settings) kernelModules;

            kernelParams = {
              useDefaults = true;
            };
            #};
            initrd = {
              systemd.enable = true;
              kernelModules = [];
              availableKernelModules = cfg.settings.availableKernelModulesIRD;
            };
            #};
          };

          tweaks = {
            networking.enable = true;
            hardening.enable = true;
            failsaves.enable = true;
            clean.enable = true;
          };

          boot = {
            enable = true;
            general = {
              silent = {
                enable = false;
              };
            };

            tmpfs = {
              enable = false;
            };

            loader = {
              timeout = 3;
              efiSupport.enable = true;
              copyToTmpfs.enable = false;

              systemd-boot = {
                enable = true;
                configurationLimit = 5;
              };
            };
          };
          optionals = {
            ricemyttydotcom = {
              enable = true;
            };
          };
        };
      };
    }
  ]);
}
