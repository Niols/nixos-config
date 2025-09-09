{ lib, ... }:

let
  inherit (lib) mkForce;

in
{
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
