{
  ## NOTE: Wallace was installed pre-Disko and therefore we will handle its disk
  ## configuration by hand. New laptops should not use this.
  x_niols.enableDiskoConfig = false;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/root";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/1873-B7F4";
      fsType = "vfat";
    };
  };

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
}
