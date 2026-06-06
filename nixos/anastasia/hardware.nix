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

  ## NOTE: To add or remove a new dataset to an existing pool:
  ##
  ##     zfs create -o mountpoint=legacy <pool>/<dataset>
  ##     zfs destroy <pool>/<dataset>
  ##
  ## This does not contain the actual mountpoint, because that is only for the
  ## mounting systemd unit, not for ZFS.
  ##
  makeZfsDataset = mountpoint: {
    type = "zfs_fs";
    inherit mountpoint;
    options.mountpoint = "legacy";
    mountOptions = [ "nofail" ];
  };

  makeZfsPool =
    { mode, datasetMountpoints }:
    {
      type = "zpool";
      inherit mode;
      mountpoint = null; # use the default, so that `option.mountpoint` works
      rootFsOptions.mountpoint = "none"; # do not mount the root of the pool
      datasets = mapAttrs (_: makeZfsDataset) datasetMountpoints;
    };

in
{
  imports = [ inputs.disko.nixosModules.disko ];

  boot.loader.systemd-boot.enable = true;

  ## Otherwise we can't find the i915 driver for the Intel integrated GPU and we
  ## get: *ERROR* GT0: GuC firmware i915/tgl_guc_70.bin: fetch failed -ENOENT
  hardware.enableRedistributableFirmware = true;

  ## Limit the RAM usage of ARC (the Adaptive Replacement Cache) to 4GB.
  ## Otherwise, it easily eats 1GB of RAM per TB of disk, which will quickly be
  ## too much for the 8GB of RAM in this machine.
  boot.extraModprobeConfig = "options zfs zfs_arc_max=4294967296";

  boot.supportedFilesystems = [ "zfs" ];

  boot.zfs = {
    devNodes = "/dev/disk/by-id";
    extraPools = [
      "important"
      "unimportant"
    ];
  };

  ## Unique among my machines. The primary use case is to ensure when using ZFS
  ## that a pool isn't imported accidentally on a wrong machine. We also prevent
  ## ZFS from force-importing pools; we will have to `zpool import -f` manually.
  networking.hostId = "f96b4cab";
  boot.zfs.forceImportAll = false;
  boot.zfs.forceImportRoot = false;

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  disko.devices = {
    disk = {
      ## Primary NVMe: small disk (256GB) for boot, swap, and OS.
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

    ## NOTE: A lot of ZFS-related Disko options only ever have an impact during
    ## initial installation, and changing them will have no effect. We still set
    ## them here for documentation purposes, but this might not actually be
    ## entirely correct, and one needs to also apply the change manually to ZFS.

    ## NOTE: We use legacy mountpoints so that ZFS does not automount these
    ## datasets itself. Instead, systemd handles mounting via the usual mount
    ## units, which avoids a conflict between the two at boot.
    ##
    ## In disko, this is `datasets.<dataset>.options.mountpoint = "legacy"`, and
    ## in ZFS, this is `zfs set mountpoint=legacy <dataset>`.

    ## NOTE: In the event that a disk dies, we want the system to boot anyway,
    ## which is possible since the system itself is not on ZFS. To achieve this,
    ## we set `nofail` on the mount options of the datasets, which means that
    ## the system will boot even if the datasets fail to mount, and we add a
    ## `TimeoutStartSec` to the ZFS import services.

    zpool.important = makeZfsPool {
      mode = "mirror";
      datasetMountpoints = {
        cloud = "/data/services/cloud";
        ftp = "/data/services/ftp";
        git = "/data/services/git";
        pictures = "/data/pictures";
        syncthing = "/data/services/syncthing";
      };
    };

    zpool.unimportant = makeZfsPool {
      mode = "raidz1";
      datasetMountpoints = {
        medias = "/data/medias";
        nix-cache = "/data/services/nix-cache";
        torrent = "/data/services/torrent";
      };
    };
  };

  systemd.services."zfs-import-important".serviceConfig.TimeoutStartSec = 60;
  systemd.services."zfs-import-unimportant".serviceConfig.TimeoutStartSec = 60;
}
