{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;

in
{
  options.x_niols.enableDiskoConfig = mkEnableOption {
    description = "Whether to use Disko for the definition of disks.";
    default = true;
  };

  config = mkIf config.x_niols.enableDiskoConfig {
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
            luks = {
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
  };
}
