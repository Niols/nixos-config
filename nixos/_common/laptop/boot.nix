{ pkgs, ... }:

{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;
        efiSupport = true;
        enableCryptodisk = true;

        ## The device on which the GRUB boot loader will be
        ## installed. The special value nodev means that a GRUB boot
        ## menu will be generated, but GRUB itself will not actually
        ## be installed. To install GRUB on multiple devices, use
        ## boot.loader.grub.devices.
        device = "nodev";
      };
    };

    ## REVIEW: I don't really know what these options do, so it would be wise to
    ## learn and to see if they indeed are sharable across all laptops.
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

    ## Allows x86_64-linux laptops to emulate aarch64, useful in particular to
    ## build Orianne's configuration.
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    tmp = {
      useTmpfs = true;
      cleanOnBoot = true;
    };
  };
}
