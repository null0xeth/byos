{
  config,
  lib,
  ...
}:
with lib; let
  filterfunc = set: builtins.head (builtins.attrNames (lib.filterAttrs (n: v: set.${n}.enable) set));
  cfg = config.profiles.kernel-interface.settings.${filterfunc config.profiles.kernel-interface.settings};
in {
  imports = [
    #./profiles/base-secured.nix
    ./sub-profiles/base-profile.nix
  ];

  options.profiles.kernel-interface = {
    settings = mkOption {
      default = {};
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "the base kernel profile with all tweaks and hardening enabled";
          name = mkOption {
            type = types.str;
            description = "the profile to enable";
          };
          kernelModules = mkOption {
            type = types.listOf types.str;
            default = [];
          };
          availableKernelModulesIRD = mkOption {
            type = types.listOf types.str;
            default = [];
          };
        };
      });
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      profiles.kernel-config."${cfg.name}" = {
        enable = true;
        settings = {
          inherit (cfg) kernelModules;
          inherit (cfg) availableKernelModulesIRD;
        };
      };
    }
  ]);
}
