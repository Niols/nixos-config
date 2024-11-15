{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  nixpkgs.hostPlatform = "aarch64-linux";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/4a1a8170-c1cf-4ef2-b27a-ced57fa60ad7";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/9468-FE29";
      fsType = "vfat";
    };
  };

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "virtio_pci"
        "virtio_scsi"
        "usbhid"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  ## REVIEW: not sure if we need this
  networking.useDHCP = lib.mkDefault true;
}
