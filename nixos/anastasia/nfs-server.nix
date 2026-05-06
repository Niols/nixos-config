{ config, lib, ... }:

let
  inherit (lib)
    concatLists
    concatMapStringsSep
    mapAttrsToList
    traceVal
    ;

  datasetMountpoints = concatLists (
    concatLists (
      mapAttrsToList (
        _: poolConfig:
        mapAttrsToList (
          _: datasetConfig:
          if datasetConfig ? mountpoint && datasetConfig.mountpoint != null then
            [ datasetConfig.mountpoint ]
          else
            [ ]
        ) poolConfig.datasets
      ) config.disko.devices.zpool
    )
  );

in
{
  services.nfs.server = {
    enable = true;

    exports = traceVal ''
      ${concatMapStringsSep "\n" (
        datasetMountpoint: "${datasetMountpoint} 192.168.1.0/8(rw,sync,no_subtree_check)"
      ) datasetMountpoints}
    '';
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];
  networking.firewall.enable = true;
}
