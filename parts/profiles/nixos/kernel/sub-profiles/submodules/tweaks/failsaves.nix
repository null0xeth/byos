{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.kernel.tweaks.failsaves;
in {
  options.modules.kernel.tweaks.failsaves = {
    enable = mkEnableOption "a lifeline to save ur ass";
  };
  config = mkIf cfg.enable {
    services = {
      # avoid the linux kernel from locking itself when we're putting too much strain on the memory
      # this helps avoid having to shut down forcefully when we OOM
      earlyoom = {
        enable = true;
        enableNotifications =
          true; # annoying, but we want to know what's killed
        freeSwapThreshold = 2;
        freeMemThreshold = 2;
        extraArgs = [
          "-g"
          "--avoid 'Hyprland|soffice|soffice.bin|firefox)$'" # things we want to not kill
          "--prefer '^(electron|.*.exe)$'" # I wish we could kill electron permanently
        ];

        # we should ideally write the logs into a designated log file; or even better, to the journal
        # for now we can hope this echo sends the log to somewhere we can observe later
        killHook = pkgs.writeShellScript "earlyoom-kill-hook" ''
          echo "Process $EARLYOOM_NAME ($EARLYOOM_PID) was killed"
        '';
      };
    };
  };
}
