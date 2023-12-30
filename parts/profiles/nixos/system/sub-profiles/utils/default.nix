{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.nixos-modules.sysutils;
in {
  imports = [./submodules];
  options.nixos-modules.sysutils = {
    enable = mkEnableOption "enable the system utility configuration module";
    tools = {
      common.enable = mkEnableOption "install frequently used system utilities";
      direnv.enable = mkEnableOption "install direnv";
      envfs.enable = mkEnableOption "install envfs";
      ld.enable = mkEnableOption "install ld";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {environment.systemPackages = with pkgs; [lshw pciutils usbutils];}

    (mkIf cfg.tools.common.enable {
      environment.systemPackages = builtins.attrValues {
        inherit (pkgs) xcp wtype wget killall devour inxi;
      };
    })

    (mkIf cfg.tools.envfs.enable {
      environment.systemPackages = builtins.attrValues {inherit (pkgs) fuse;};
      services.envfs.enable = true;
    })

    (mkIf cfg.tools.direnv.enable {
      sysutils.direnv = {
        enable = true;
      };
    })

    (mkIf cfg.tools.ld.enable {
      programs.nix-ld = {
        enable = true;
        libraries = builtins.attrValues {
          inherit (pkgs.stdenv.cc) cc;
          inherit
            (pkgs.xorg)
            libX11
            libXScrnSaver
            libXcomposite
            libXcursor
            libXdamage
            libXext
            libXfixes
            libXi
            libXrandr
            libXrender
            libXtst
            libxkbfile
            libxcb
            libxshmfence
            ;

          inherit
            (pkgs)
            fuse3
            alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            curl
            dbus
            expat
            fontconfig
            freetype
            gdk-pixbuf
            glib
            gtk3
            libGL
            libappindicator-gtk3
            libdrm
            libnotify
            libpulseaudio
            libuuid
            libusb1
            libxkbcommon
            mesa
            nspr
            nss
            pango
            pipewire
            systemd
            icu
            openssl
            zlib
            ;
        };
      };
    })
  ]);
}
