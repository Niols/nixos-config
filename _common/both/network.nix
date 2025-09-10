{ config, ... }:

{
  networking = {
    hostName = config.x_niols.thisDevicesNameLower;
    domain = "niols.fr";
  };
}
