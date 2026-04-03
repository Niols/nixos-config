{
  inputs,
  lib,
  ...
}:

let
  inherit (lib)
    mapAttrs
    ;

  make100PercentZfsDisk =
    { device, pool }:
    {
      type = "disk";
      inherit device;
      content = {
        type = "gpt";
        partitions.zfs = {
          size = "100%";
          content = {
            type = "zfs";
            inherit pool;
          };
        };
      };
    };

in
{
  imports = [ inputs.disko.nixosModules.disko ];

  boot = {
    loader.grub.device = "nodev";
  };

  disko.devices = {

    disk =
      ## Primary NVMe: small disk (256GB) for boot, swap, and OS.

      {
        primary = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-WDC_PC_SN730_SDBQNTY-256G-1001_21456E803680";
          content = {
            type = "gpt";
            partitions = {
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
              swap = {
                size = "2G"; # no need for much; safety net against OOM
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

        ## Secondary NVMe: 1TB, for now part of the `important` pool; but later
        ## should serve as cache for the ZFS pools.

        secondary = make100PercentZfsDisk {
          device = "/dev/disk/by-id/nvme-CT1000P5PSSD8_2207357F6ED5";
          pool = "important";
        };
      }
      //

        ## SATA disks: all fully dedicated to ZFS pools, some to the important
        ## one and some to the unimportant one. The 1TB (SATA6) gets mirrored
        ## with the secondary NVMe for the 1TB important pool, and the 3 x 2TBs
        ## get RAIDZed together for the 4TB unimportant pool.

        mapAttrs (_: make100PercentZfsDisk) {
          sata1 = {
            device = "/dev/disk/by-id/ata-WDC_WD20EARS-00MVWB0_WD-WMAZA3332695";
            pool = "unimportant";
          };
          sata2 = {
            device = "/dev/disk/by-id/ata-WDC_WD20EARS-00MVWB0_WD-WMAZA3532641";
            pool = "unimportant";
          };
          sata3 = {
            device = "/dev/disk/by-id/ata-WDC_WD20EARS-00MVWB0_WD-WMAZA3541730";
            pool = "unimportant";
          };
          sata6 = {
            device = "/dev/disk/by-id/ata-ST31000528AS_5VP7SV6M";
            pool = "important";
          };
        };

    ## ZFS pools: one important for cloud data, pictures, etc., and one
    ## unimportant for media, etc. Both will be backed up to Hester anyway, but
    ## we don't want a long interruption for the important data, and we don't
    ## mind as much for medias.

    zpool.important = {
      type = "zpool";
      mode = "mirror";
      datasets = {
        "pictures" = {
          type = "zfs_fs";
          options.mountpoint = "/data/pictures";
        };
        "services" = {
          type = "zfs_fs";
          options.mountpoint = "/data/services";
        };
      };
    };

    zpool.unimportant = {
      type = "zpool";
      mode = "raidz1";
      datasets = {
        "medias" = {
          type = "zfs_fs";
          options.mountpoint = "/data/medias";
        };
      };
    };
  };
}
