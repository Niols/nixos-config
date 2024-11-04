{ lib, secrets, config, ... }:

let inherit (lib) mkForce;

in {
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

  ##############################################################################
  ## VPN for the Fediversity project

  networking.wireguard = {
    enable = true;
    interfaces = {
      fediversity = {
        ips = [ "10.197.16.4/20" "fd3d:b64f:631d:8284::4/64" ];
        privateKeyFile =
          config.age.secrets.wireguard-wallace-fediversity-private-key.path;
        peers = [{
          publicKey = "TKTBW6RUjsMc9I9bH31vBUMZZByZVhL7rDENHjEcgyw=";
          allowedIPs =
            [ "10.197.16.0/20" "192.168.51.0/24" "fd3d:b64f:631d:8284::/64" ];
          endpoint = "vpn.fediversity.eu:51820";
        }];
      };
    };
  };

  age.secrets.wireguard-wallace-fediversity-private-key.file =
    "${secrets}/wireguard-wallace-fediversity-private-key.age";
}
