{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; {
  environment = {
    systemPackages = with pkgs; [
      inputs.nh.packages.${pkgs.system}.default
      nix-output-monitor
    ];
  };

  system.stateVersion = "24.05";

  nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = false;
    };
  };

  # faster rebuilding
  documentation = {
    doc.enable = false;
    nixos.enable = true;
    info.enable = false;
    man = {
      enable = lib.mkDefault true;
      generateCaches = lib.mkDefault true;
    };
  };

  nix = {
    package = pkgs.nixFlakes;
    distributedBuilds = true;
    nixPath = ["nixpkgs=flake:nixpkgs"];
    settings = {
      extra-experimental-features =
        [
          "flakes" # flakes
          "nix-command" # experimental nix commands
          "recursive-nix" # let nix invoke itself
          "auto-allocate-uids"
          "ca-derivations" # content addressed nix
          "repl-flake" # allow passing installables to nix repl
          "cgroups" # allow nix to execute builds inside cgroups
          "fetch-closure"
        ]
        ++ lib.optional
        (lib.versionOlder (lib.versions.majorMinor config.nix.package.version)
          "2.18")
        # allows to drop references from filesystem images
        "discard-references";

      # Fallback quickly if substituters are not available.
      connect-timeout = 5;
      flake-registry = "/etc/nix/registry.json";
      # Free up to 10GiB whenever there is less than 5GB left.
      # this setting is in bytes, so we multiply with 1024 thrice
      min-free = "${toString (5 * 1024 * 1024 * 1024)}";
      max-free = "${toString (10 * 1024 * 1024 * 1024)}";
      auto-optimise-store = true;
      builders-use-substitutes = true;
      max-jobs = "auto";
      sandbox = true;
      allowed-users = ["root" "null0x" "@wheel"];
      # only allow sudo users to manage the nix store
      trusted-users = ["root" "null0x" "@wheel"];
      # continue building derivations if one fails
      keep-going = true;
      auto-allocate-uids = true;
      system-features = lib.mkDefault [
        "kvm"
        "big-parallel"
        "recursive-nix"
        "nixos-test"
        "benchmark"
      ];
      # maximum number of parallel TCP connections used to fetch imports and binary caches, 0 means no limit
      http-connections = 50;
      # whether to accept nix configuration from a flake without prompting
      accept-flake-config = false;
      # execute builds inside cgroups
      use-cgroups = true;

      substituters = [
        "https://cache.nixos.org" # funny binary cache
        "https://nix-community.cachix.org" # nix-community cache
        "https://hyprland.cachix.org" # hyprland
      ];

      extra-substituters = [
        #"https://null0xeth.cachix.org" # cached stuff from my flake outputs
        "https://nixpkgs-wayland.cachix.org" # automated builds of *some* wayland packages
        #"https://nix-community.cachix.org" # nix-community cache
        #"https://hyprland.cachix.org" # hyprland
        "https://nixpkgs-unfree.cachix.org" # unfree-package cache
        "https://anyrun.cachix.org" # anyrun program launcher
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];

      extra-trusted-public-keys = [
        #"null0xeth.cachix.org-1:iMl0YL/u/bBKPHCPcFnZKLWP8m8dIulM7tzKKyGmp3A="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        #"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        #"hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      ];
    };
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };
    # automatically optimize nix store my removing hard links
    # do it after the gc
    optimise = {
      automatic = true;
      dates = ["21:00"];
    };
    # Define global flakes for this system
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
    };
  };

  system = {
    extraSystemBuilderCmds = ''
      ln -sv ${inputs.nixpkgs} $out/nixpkgs
    '';
  };

  environment.profiles = [
    "/home/$USER/.local/state/nix/profiles" # Hardcoding bad but stuff seems to break otherwise
    "/etc/profiles/per-user/$USER"
  ];

  # Make builds to be more likely killed than important services.
  # 100 is the default for user slices and 500 is systemd-coredumpd@
  # We rather want a build to be killed than our precious user sessions as builds can be easily restarted.
  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250;
  systemd.tmpfiles.rules = ["D /nix/var/nix/profiles/per-user/root 755 root root - -"];
  #systemd.tmpfiles.rules = ["L+ ${nixpkgsPath}     - - - - ${inputs.nixpkgs}"];
}
