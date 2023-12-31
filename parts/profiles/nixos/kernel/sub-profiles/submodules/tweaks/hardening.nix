{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.kernel.tweaks.hardening;
in {
  options.modules.kernel.tweaks.hardening = {
    enable = mkEnableOption "a more secure kernel configuration";
  };
  config = mkIf cfg.enable {
    boot = {
      kernel.sysctl = {
        # Hardening:
        "kernel.sysrq" = 0;
        "kernel.kptr_restrict" = 2;
        "net.core.bpf_jit_enable" = false;
        "kernel.ftrace_enabled" = false;
        "kernel.dmesg_restrict" = 1;
      };
    };
    systemd = let
      extraConfig = ''
        DefaultTimeoutStopSec=15s
      '';
    in {
      inherit extraConfig;
      user = {inherit extraConfig;};
      services = {
        "getty@tty1".enable = false;
        "autovt@tty1".enable = false;
        "getty@tty7".enable = false;
        "autovt@tty7".enable = false;
      };
    };
  };
}
