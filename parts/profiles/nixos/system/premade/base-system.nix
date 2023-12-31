{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  name = "base-system";
  cfg = config.profiles.system-config.${name};
in {
  imports = [
    ./sub-profiles/base-profile.nix
  ];

  options.profiles.system-config.${name} = {
    enable =
      mkEnableOption
      "the base system profile with Hyprland support enabled";
  };

  config = mkIf cfg.enable {
    profiles.system.preset.${name} = {
      enable = true;
      name = "${name}";
      profile = {
        firmware = {
          enable = true;
          packages = [];
        };
      };
      fonts = {
        enable = true;
        packages = with pkgs; [
          # Icon fonts:
          material-symbols

          # Normal fonts:
          font-awesome
          jost
          lexend
          noto-fonts
          noto-fonts-cjk
          noto-fonts-emoji
          roboto

          # NerdFonts:
          (nerdfonts.override {fonts = ["FiraCode" "JetBrainsMono"];})
        ];
        defaults = {
          serif = ["Noto Serif" "Noto Color Emoji"];
          sansSerif = ["Noto Sans" "Noto Color Emoji"];
          monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
          emoji = ["Noto Color Emoji"];
        };
      };
      sysutils = {
        enable = true;
        tools = {
          common.enable = true;
          direnv.enable = true;
          envfs.enable = true;
          ld.enable = true; # no point
        };
      };
    };
  };
}
