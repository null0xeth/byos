# BYOS

## What is BYOS?

BYOS or Build Your Own System,
is a smart templating engine that configures your system with sane defaults based on the input provided.
As of right now, BYOS is able to configure the following:
```
Hardware:
├─ CPU (Intel only at the moment)
├─ Audio, Bluetooth, Storage
├─ Thunderbolt, Sensors, Logitech mice

Kernel:
├─ Sane, and safe kernel settings.
├─ Optional kernel tweaks (networking, etc)

Graphical:
├─ Xserver

System:
├─ Firmware
├─ Fonts
├─ Common system utils

Security:
├─ Agenix support
├─ Yubikey support
├─ Sudo
```
## Quick Start

```bash
nix flake init -t github:null0xeth/byos

or

add inputs.byos.nixosModules.byosBuilder to your imports.
```

## Configuration

An example can be found inside the templates directory under
```parts/roles/nixos/workstation/intel/poc.nix```
