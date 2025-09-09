{ lib, ... }:

let
  inherit (lib) mkForce;

in
{
  ############################################################################
  ## Networking
  ##
  ## The global useDHCP flag is deprecated, therefore explicitly set
  ## to false here. wPer-interface useDHCP will be mandatory in the
  ## future, so this generated config replicates the default
  ## behaviour.

  networking = {
    hostName = "wallace";

    useDHCP = false;
    interfaces.wlp0s20f3.useDHCP = true;

    networkmanager.enable = true;

    nameservers = [
      "1.1.1.1"
      "1.0.0.1" # # Cloudflare
      "8.8.8.8"
      "8.8.4.4" # # Google
    ];
  };

  ##############################################################################
  ## WiFi access point for other devices

  services.create_ap = {
    enable = true;
    settings = {
      INTERNET_IFACE = "wlp0s20f3";
      WIFI_IFACE = "wlp0s20f3";
      SSID = "Wallace";
      PASSPHRASE = "ReKuYm05";
      FREQ_BAND = "2.4";
    };
  };
  ## Do not make the unit wanted by anything, such that it will exist but not
  ## start automatically on start-up.
  systemd.services.create_ap.wantedBy = mkForce [ ];
}
