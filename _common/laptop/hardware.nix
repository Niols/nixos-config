{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge;

in
{
  options.x_niols.enableDiskoConfig = mkEnableOption {
    description = "Whether to use Disko for the definition of disks.";
    default = true;
  };

  config = mkMerge [

    ## Disk configuration via Disko, unless specifically disabled.
    (mkIf config.x_niols.enableDiskoConfig {
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
    })

    ## REVIEW: What do these options do? Can they safely be shared with other
    ## laptops?
    {
      powerManagement.cpuFreqGovernor = "powersave";
      hardware.cpu.intel.updateMicrocode = true;
      hardware.enableRedistributableFirmware = true;
    }

    ## Sound
    {
      ## Force opt-out of Pipewire, the default, that doesn't work so well for us.
      ## Use good old pulseaudio instead.
      services.pipewire.enable = false;
      services.pulseaudio.enable = true;
    }

    ## Graphics
    {
      services.picom.enable = true;
    }
  ];
}
