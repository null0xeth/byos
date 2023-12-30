{
  inputs,
  pkgs,
  ...
}: {
  users.users.jdoe = {
    isNormalUser = true;
    description = "its me, mario";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "seat"
      "dri"
      "power"
      "input"
      "lp"
      "plugdev"
      "systemd-journal"
      "audio"
    ];

    shell = pkgs.zsh;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs;};
    users.jdoe = {imports = [./home.nix];};
  };

  programs = {
    zsh.enable = true;
  };
}
