## Usage: import this file and set the `disko.devices.disk.root.device`.

{
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.enableCryptodisk = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev"; # Add this line - don't install to MBR
  boot.loader.grub.useOSProber = false; # Disable OS probing

  boot.tmp.useTmpfs = true;
  boot.tmp.cleanOnBoot = true;

  disko.devices.disk.main.device = "/dev/nvme0n1";

  ## FIXME: factorise
  disko.devices = {
    disk.main = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ## Boot partition, 1GB outside of LUKS.
          ##
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
          ## an LVM pool of physical volumes. See `lvm_vg.pool` later.
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
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };

    ## LVM pool, inside the LUKS partition, containing the `swap` and `root`
    ## logical volumes.
    ##
    lvm_vg.pool = {
      type = "lvm_vg";
      lvs = {
        swap = {
          size = "32G";
          content.type = "swap";
        };

        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
