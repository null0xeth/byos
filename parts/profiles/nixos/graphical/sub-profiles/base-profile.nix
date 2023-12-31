{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mdDoc mkIf types mkMerge;
  filterfunc = set: builtins.head (builtins.attrNames (lib.filterAttrs (n: _: set.${n}.enable) set));
  cfg = config.profiles.graphical.preset.${filterfunc config.profiles.graphical.preset};

  enableModule = lib.types.submodule {
    options = {
      enable = mkEnableOption "";
    };
  };
in {
  options.profiles.graphical = {
    preset = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "the default graphical profile template";
          name = mkOption {
            type = types.str;
            description = mdDoc "The slug used to refer to this profile";
            default = "default-security-template";
          };
          base = mkOption {
            type = types.enum ["gtk"];
            description = mdDoc "The base layer used for rendering the system's gui";
            default = "gtk";
          };

          settings = mkOption {
            type = types.submodule {
              options = {
                system = mkOption {
                  type = types.submodule {
                    options = {
                      dbus = mkOption {
                        type = enableModule;
                      };
                      xserver = mkOption {
                        type = enableModule;
                      };
                    };
                  };
                };
                core = mkOption {
                  type = types.submodule {
                    options = {
                      desktopManager = mkOption {
                        type = types.submodule {
                          options = {
                            enable = mkEnableOption "enable the desktopmanager module";
                            active = mkOption {
                              type = types.enum ["gnome" "none"];
                              default = "none";
                            };
                          };
                        };
                      };
                      displayManager = mkOption {
                        type = types.submodule {
                          options = {
                            enable = mkEnableOption "enable the displaymanager module";
                            active = mkOption {
                              type = types.enum ["gdm" "none"];
                              default = "none";
                            };
                          };
                        };
                      };
                      libinput = mkOption {
                        type = enableModule;
                      };
                      extra = mkOption {
                        type = types.submodule {
                          options = {
                            hyperlandSupport = mkOption {
                              type = enableModule;
                            };
                            exportConfiguration = mkOption {
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
    (mkIf cfg.settings.system.dbus.enable {
      services.dbus = {
        enable = true;
        implementation = "broker";
      };
    })

    (mkIf (cfg.base == "gtk") {
      services = {
        dbus = {
          packages = with pkgs; [dconf];
        };
        udev = {
          packages = with pkgs; [gnome.gnome-settings-daemon];
        };
        xserver = {
          gdk-pixbuf.modulePackages = [pkgs.librsvg];
        };
      };
    })

    (mkIf cfg.settings.system.xserver.enable (mkMerge [
      {
        services.xserver = {
          enable = true;
          xkbVariant = "";
        };

        xdg.portal.enable = true;
      }

      (mkIf cfg.settings.core.desktopManager.enable {
        services.xserver = {
          desktopManager = {
            gnome = {
              enable = true;
            };
          };
        };
      })

      (mkIf cfg.settings.core.displayManager.enable (mkMerge [
        (mkIf cfg.settings.core.extra.hyperlandSupport.enable {
          services.xserver = {
            displayManager = {
              sessionPackages = [inputs.hyprland.packages.x86_64-linux.default];
            };
          };
        })

        (mkIf (cfg.settings.core.displayManager.active == "gdm") {
          assertions = [
            {
              assertion = (cfg.base == "gtk") && (cfg.settings.core.displayManager.active == "gdm");
              message = "Please set `base` to `gtk` in order to use `gdm` as displaymanager.";
            }
          ];

          services.xserver = {
            gdk-pixbuf = {
              modulePackages = [pkgs.librsvg];
            };
            displayManager = {
              gdm = {
                enable = true;
              };
            };
          };
        })
      ]))

      (mkIf cfg.settings.core.extra.exportConfiguration.enable {
        services.xserver = {
          exportConfiguration = true;
        };
      })

      (mkIf cfg.settings.system.dbus.enable {
        services.xserver = {
          updateDbusEnvironment = true;
        };
      })

      (mkIf cfg.settings.core.libinput.enable {
        services.xserver = {
          libinput = {
            enable = true;
            mouse = {
              accelProfile = "flat";
            };
          };
        };
      })
    ]))
  ]);
}
