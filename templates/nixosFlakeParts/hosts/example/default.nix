{
  lib,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../modules/nixos
  ];

  ## THIS IS COPIED FROM HARDWARE-CONFIG. DOUBLE CHECK BEFORE RUNNING THIS
  roles = {
    workstation.poc = {
      enable = true;
      overrides = {
        kernelModules = ["usbhid" "xhci_pci" "ahci" "nvme"];
        initrd = {
          availableKernelModules = [
            "usbhid"
            "sd_mod"
            "dm_mod"
            "uas"
            "usb_storage"
            "rtsx_pci_sdmmc" # Realtek PCI-Express SD/MMC Card Interface driver
          ];
        };
      };
    };
  };

  age = {
    rekey = {
      cacheDir = ''/var/tmp/agenix-rekey/"$UID"'';
      hostPubkey = ./secrets/your/ssh/host/keys;
      extraEncryptionPubkeys = [../path/to/your/secretIdentity/pubKey];
      masterIdentities = [../path/to/secretIdentity];
    };
  };

  ## THIS IS COPIED FROM HARDWARE-CONFIG. DOUBLE CHECK BEFORE RUNNING THIS
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/01f1cf1e-4344-4940-aa10-bdc16c187711";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/11C2-7FEB";
      fsType = "vfat";
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/81cc56c3-21a9-4dfb-8b99-649f41aabf94";
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
