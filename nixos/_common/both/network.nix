{ config, ... }:

{
  networking = {
    hostName = config.x_niols.thisDevicesNameLower;
    domain = "niols.fr";

    nameservers = [
      "1.1.1.1"
      "1.0.0.1" # Cloudflare
      "8.8.8.8"
      "8.8.4.4" # Google
    ];
  };
}
