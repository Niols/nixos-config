{
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.enableCryptodisk = true;
  boot.loader.grub.device = "nodev"; # Add this line - don't install to MBR
  boot.loader.grub.useOSProber = false; # Disable OS probing
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.grub.forcei686 = false; # Ensure this is not set to true

  boot.tmp.useTmpfs = true;
  boot.tmp.cleanOnBoot = true;

  disko.devices.disk.main.device = "/dev/nvme0n1";
}
