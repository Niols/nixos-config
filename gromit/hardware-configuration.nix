## Usage: import this file and set the `disko.devices.disk.root.device`.

{
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.enableCryptodisk = true;

  ## The device on which the GRUB boot loader will be installed. The special
  ## value nodev means that a GRUB boot menu will be generated, but GRUB itself
  ## will not actually be installed. To install GRUB on multiple devices, use
  ## boot.loader.grub.devices.
  boot.loader.grub.device = "nodev";

  boot.tmp.useTmpfs = true;
  boot.tmp.cleanOnBoot = true;

  disko.devices.disk.root.device = "/dev/nvme0n1";

  ## FIXME: factorise
  disko.devices.disk = {
    root = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {

          ## Boot partition, 1GB outside of LUKS.
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          ## LUKS encrypted partition, 100% of the remaining space. It contains
          ## only one filesystem, the root of everything.
          ##
          ## NOTE: LUKS passphrase will be prompted interactively only.
          ##
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings.allowDiscards = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
