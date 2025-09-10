{ pkgs, ... }:

{
  ## TODO: experiment with the following
  ##
  ## boot.loader.grub.backgroundColor
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.backgroundColor
  ##
  ## boot.loader.grub.extraConfig
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.extraConfig
  ##
  ## boot.loader.grub.fontSize
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.fontSize
  ##
  ## boot.loader.grub.gfxmodeBios
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.gfxmodeBios
  ##
  ## boot.loader.grub.gfxmodeEfi
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.gfxmodeEfi
  ##
  ## boot.loader.grub.splashImage
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.splashImage
  ##
  ## boot.loader.grub.theme
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.theme

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

        ## FIXME: Attempt to use a Grub theme. cf:
        ## - Nix package: `legacyPackages.x86_64-linux.breeze-grub`
        ## - Nix package: `legacyPackages.x86_64-linux.nixos-grub2-theme`
        ## - https://fostips.com/boot-menu-modern-stylish-grub-themes/
        ## - https://github.com/vinceliuice/grub2-themes

        ## FIXME: to try
        ##
        ## Grub menu is painted really slowly on HiDPI, so we lower the
        ## resolution. Unfortunately, scaling to 1280x720 (keeping aspect
        ## ratio) doesn't seem to work, so we just pick another low one.
        ##
        ## Tried:
        ## - 1024x768 (works!)
        ## - 1280x800 (does not work)
        ## - 1280x720 (does not work)
        ## - 1280x960 (does not work)
        ## - 1400x900 (does not work)
        ##
        gfxmodeEfi = "1024x768";
        #gfxmodeBios = "1024x768";
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

    initrd.luks.devices = {
      crypt = {
        device = "/dev/nvme0n1p2";
        preLVM = true;
      };
    };

    tmp = {
      useTmpfs = true;
      cleanOnBoot = true;
    };
  };
}
