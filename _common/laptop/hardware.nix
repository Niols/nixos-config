{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    mkIf
    mkMerge
    types
    ;

in
{
  options.x_niols = {
    enableDiskoConfig = mkOption {
      description = ''
        Whether to use Disko for the definition of disks. This is enabled by
        default and should only be disabled for legacy devices, installed before
        Disko was a thing in this configuration.
      '';
      type = types.bool;
      default = true;
    };

    unencryptedOptSize = mkOption {
      description = ''
        The size of the unencrypted `/opt` partition, or `null` to not have one.
        This partition can be useful for video games, where security matters
        less, but IO performances matter more.
      '';
      example = "200GB";
      type = with types; nullOr str;
      default = null;
    };
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
                content = {
                  type = "luks";
                  name = "crypted";
                  settings.allowDiscards = true;
                  content = {
                    type = "lvm_pv";
                    vg = "pool";
                  };
                };
              }
              // (
                if config.x_niols.unencryptedOptSize == null then
                  { size = "100%"; }
                else
                  { end = "-${config.x_niols.unencryptedOptSize}"; }
              );
            }
            // (
              if config.x_niols.unencryptedOptSize == null then
                { }
              else
                {
                  opt = {
                    size = "100%";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/opt";
                    };
                  };
                }
            );
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
