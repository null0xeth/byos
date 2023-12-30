{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.security-modules.yubikey;
in {
  options.security-modules.yubikey = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the yubikey security module";
    };
    settings = {
      touchDetector = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable the yubikey touch detector daemon";
        };
      };
      udev = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable the yubikey udev configurations and packages";
        };
      };
      configuration = {
        idVendor = mkOption {
          type = types.str;
          default = null;
          description = "Your yubikey vendor id";
        };
        idProduct = mkOption {
          type = types.str;
          default = null;
          description = "Your yubikey product id";
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment = {
        systemPackages = with pkgs; [
          age-plugin-yubikey
          yubikey-manager
          yubikey-manager-qt
          yubikey-personalization
          yubikey-personalization-gui # gui
          #yubioath-flutter # gui
          yubico-piv-tool
          yubikey-agent
        ];
      };

      services = {
        pcscd.enable = true;
        yubikey-agent.enable = true;
      };
    }

    (mkIf cfg.settings.touchDetector.enable {
      environment = {
        systemPackages = [pkgs.yubikey-touch-detector];
        sessionVariables = {
          YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY = "true";
        };
      };
      programs = {
        yubikey-touch-detector.enable = true;
      };
    })

    (mkIf cfg.settings.udev.enable (mkMerge [
      (let
        inherit (cfg.settings.configuration) idVendor idProduct;
        notEmpty = idVendor != null && idProduct != null;
      in {
        services.udev = mkIf notEmpty {
          packages = with pkgs; [yubikey-personalization];
          extraRules = ''
            SUBSYSTEM="usb", ATTR{idVendor}=="${idVendor}", ATTR{idProduct}=="${idProduct}", ENV{ID_SECURITY_TOKEN}="1", group="wheel"
          '';
        };
      })
    ]))
  ]);
}
