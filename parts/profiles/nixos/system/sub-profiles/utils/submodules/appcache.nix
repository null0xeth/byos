{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.nixos-modules.system.caching;
in {
  options.nixos-modules.system.caching = {
    firefox = {enable = mkEnableOption "Whether to cache firefox in /tmpfs";};
  };

  config = mkIf cfg.firefox.enable {
    security.polkit.enable = true;

    # Firefox cache on tmpfs
    fileSystems."/home/null0x/.cache/mozilla/firefox" = {
      device = "tmpfs";
      fsType = "tmpfs";
      noCheck = true;
      options = ["noatime" "nodev" "nosuid" "size=128M"];
    };

    # enable the unified cgroup hierarchy (cgroupsv2)
    systemd.enableUnifiedCgroupHierarchy = true;
  };
}
