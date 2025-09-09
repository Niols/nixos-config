{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

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

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
      ];
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];

    ## Allows Wallace to emulate aarch64, useful in particular to build
    ## Orianne's configuration.
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.docker0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
