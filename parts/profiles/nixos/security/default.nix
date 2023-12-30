{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  filterfunc = set: builtins.head (builtins.attrNames (lib.filterAttrs (n: _: set.${n}.enable) set));
  cfg = config.profiles.security.preset.${filterfunc config.profiles.security.preset};

  enableModule = lib.types.submodule {
    options = {
      enable = mkEnableOption "";
    };
  };
in {
  imports = [./submodules/yubikey.nix];

  options.profiles.security = {
    preset = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "the default security profile template";

          name = mkOption {
            type = types.str;
            description = mdDoc "The slug used to refer to this profile";
            default = "default-security-template";
          };

          modules = mkOption {
            type = types.submodule {
              options = {
                agenix = mkOption {
                  type = enableModule;
                };
                yubikey = mkOption {
                  type = types.submodule {
                    options = {
                      enable = mkEnableOption "support for yubikey mfa";
                      settings = mkOption {
                        type = types.submodule {
                          options = {
                            configuration = mkOption {
                              type = types.submodule {
                                options = {
                                  idVendor = mkOption {
                                    type = types.str;
                                    default = null;
                                    description = "Yubikey vendor id";
                                  };
                                  idProduct = mkOption {
                                    type = types.str;
                                    default = null;
                                    description = "Yubikey product id";
                                  };
                                };
                              };
                            };
                            udev = mkOption {
                              type = enableModule;
                            };
                            touchDetector = mkOption {
                              type = enableModule;
                            };
                          };
                        };
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
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.modules.yubikey.enable {
      assertions = [
        {
          assertion = (cfg.modules.yubikey.settings.configuration.idVendor != null) && (cfg.modules.yubikey.settings.configuration.idProduct != null);
          message = "You have enabled the `yubikey` profile, but omitted the idVendor and idProduct";
        }
      ];

      security-modules.yubikey = {
        enable = true;
        settings = {
          inherit (cfg.modules.yubikey.settings) udev touchDetector configuration;
        };
      };
    })

    (mkIf cfg.modules.agenix.enable {
      nix.settings.extra-sandbox-paths = ["/var/tmp/agenix-rekey"];
      systemd.tmpfiles.rules = ["d /var/tmp/agenix-rekey 1777 root root"];
    })
    {
      environment.systemPackages = with pkgs; [
        pinentry-gnome
        gcr
        cfssl
        pcsctools
      ];

      security.polkit.enable = true;
      systemd = {
        user.services.polkit-gnome-authentication-agent-1 = {
          description = "polkit-gnome-authentication-agent-1";
          wantedBy = ["graphical-session.target"];
          wants = ["graphical-session.target"];
          after = ["graphical-session.target"];

          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
        };
        services = {
          seatd = {
            enable = true;
            description = "Seat management Daemon";
            script = "${lib.getExe pkgs.seatd} -g wheel";

            serviceConfig = {
              Type = "simple";
              Restart = "always";
              RestartSec = "1";
            };

            wantedBy = ["graphical-session.target"];
          };
        };
      };
      security = {
        doas = {
          enable = true;
          extraConfig = ''
            permit persist keepenv :wheel
          '';
        };

        pam.services.swaylock.text = ''
          auth include login
        '';

        sudo.extraRules = [
          {
            commands = [
              {
                command = "/run/current-system/sw/bin/nixos-rebuild";
                options = ["NOPASSWD"];
              }
            ];
            groups = ["wheel"];
          }
        ];
      };
    }
  ]);
}
