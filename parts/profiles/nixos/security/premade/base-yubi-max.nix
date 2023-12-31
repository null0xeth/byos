{
  config,
  lib,
  ...
}:
with lib; let
  name = "base-yubi-max";
  cfg = config.profiles.security-config.${name};
in {
  imports = [
    ./sub-profiles/base-profile.nix
  ];

  options.profiles.security-config.${name} = {
    enable =
      mkEnableOption
      "the base security profile with a yubikey support enabled";
  };

  config = mkIf cfg.enable {
    profiles.security.preset.base-yubi-max = {
      enable = true;
      modules = {
        agenix = {
          enable = true;
        };
        yubikey = {
          enable = true;
          settings = {
            configuration = {
              idVendor = "1050";
              idProduct = "0407";
            };
            udev = {
              enable = true;
            };
            touchDetector = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
