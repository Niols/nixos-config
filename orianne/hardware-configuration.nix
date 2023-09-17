{ modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/bc49ebc1-f241-43da-9b4e-1f4c91405121";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/329D-162C";
      fsType = "vfat";
    };
  };

  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };

    initrd = {
      availableKernelModules = [ "nvme" ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };
}
