{
  inputs,
  ...
}:

{
  imports = [ inputs.disko.nixosModules.disko ];

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
