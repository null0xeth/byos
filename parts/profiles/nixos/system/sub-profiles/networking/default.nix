{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  filterfunc = set: builtins.head (builtins.attrNames (lib.filterAttrs (n: _: set.${n}.enable) set));
  cfg = config.profiles.networking.preset.${filterfunc config.profiles.networking.preset};
in {
  options.profiles.networking = {
    preset = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "the default graphical networking template";
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
      });
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Allow PMTU / DHCP
      environment.systemPackages = with pkgs; [mullvad-vpn libva-utils networkmanagerapplet];

      networking = {
        hostName = "${cfg.hostName}";
        firewall = {
          allowPing = true;
          logRefusedConnections = lib.mkDefault false;
        };
        useNetworkd = lib.mkDefault true;
        useDHCP = lib.mkDefault false;
      };

      systemd = {
        services = {
          NetworkManager-wait-online.enable = false;
          systemd-networkd.stopIfChanged = false;
          systemd-resolved.stopIfChanged = false;
        };
        network = {
          wait-online.enable = false;
        };
      };

      services.mullvad-vpn.enable = true;
    }
    (mkIf (cfg.extraHosts != null) {
      networking = {
        inherit (cfg) extraHosts;
      };
    })
  ]);
}
