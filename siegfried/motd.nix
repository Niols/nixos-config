{ config, ... }:

{
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = config.x_niols.thisDevicesName;
    hostcolour = "yellow";
    noSwap = true;
  };
}
