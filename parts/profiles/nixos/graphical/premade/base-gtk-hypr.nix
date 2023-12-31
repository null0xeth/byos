{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  name = "base-gtk-hypr";
  cfg = config.profiles.graphical-config.${name};
in {
  imports = [
    ./sub-profiles/base-profile.nix
  ];

  options.profiles.graphical-config.${name} = {
    enable =
      mkEnableOption
      "the base graphical profile with Hyprland support enabled";
  };

  config = mkIf cfg.enable {
    profiles.graphical.preset.${name} = {
      enable = true;
      name = "${name}";
      base = "gtk";

      settings = {
        system = {
          dbus = {
            enable = true;
          };
          xserver = {
            enable = true;
          };
        };
        core = {
          desktopManager = {
            enable = true;
            active = "gnome";
          };
          displayManager = {
            enable = true;
            active = "gdm";
          };
          libinput = {
            enable = true;
          };
          extra = {
            hyperlandSupport = {
              enable = true;
            };
            exportConfiguration = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
