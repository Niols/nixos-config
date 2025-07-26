## Usage: import this file and set the `disko.devices.disk.root.device`.

{
  disko.devices.disk.root.device = "/dev/nvme0n1";

  ## Common part:

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
