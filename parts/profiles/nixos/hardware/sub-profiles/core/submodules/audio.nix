{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.sub-modules.hardware.audio;
in {
  options.sub-modules.hardware.audio = {
    enable = mkEnableOption "Whether to enable audio";
  };

  config = mkIf cfg.enable {
    sound.enable = true;
    security.rtkit.enable = true;
    hardware.pulseaudio.enable = false;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    services.mpd = {
      enable = true;
      musicDirectory = "/home/null0x/music";
      extraConfig = ''
        audio_output {
        type "pulse"
        name "PulseAudio" # this can be whatever you want
        server "127.0.0.1" # add this line - MPD must connect to the local sound server
        }
      '';
    };
  };
}
