{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/home
  ];

  # Be kind to systemD:
  targets.genericLinux.enable = true;
  systemd.user.startServices = "sd-switch";

  ## NIX CONFIG:
  nix = {
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
    };
  };
  ##

  # Home-Manager configuration:
  home = {
    username = "jdoe";
    homeDirectory = "/home/jdoe";
    sessionPath = ["/run/current-system/sw/bin" "/etc/profiles/per-user/jdoe/bin"];
    stateVersion = "24.05";

    # Packages that should be installed by HM:
    packages = with pkgs; [
      cached-nix-shell
      nix-tree
      nix-prefetch-git
      material-icons
      tree
      gh
    ];

    ## NIX CONFIG:
    sessionVariables.NIX_PATH = "nixpkgs=flake:nixpkgs$\{NIX_PATH:+:$NIX_PATH}";
  };

  programs.home-manager.enable = true;
}
