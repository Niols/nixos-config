{ config, lib, ... }:

let
  inherit (lib)
    mkForce
    mkOption
    types
    toSentenceCase
    ;

in
{
  options.x_niols.thisLaptopsWifiInterface = mkOption {
    description = ''
      The WiFi interface of this laptop, eg. `wlp0s20f3`.
    '';
    type = types.str;
  };

  config = {
    ############################################################################
    ## Networking
    ##
    ## The global useDHCP flag is deprecated, therefore explicitly set
    ## to false here. wPer-interface useDHCP will be mandatory in the
    ## future, so this generated config replicates the default
    ## behaviour.

    networking = {
      useDHCP = false;
      interfaces.${config.x_niols.thisLaptopsWifiInterface}.useDHCP = true;
      networkmanager.enable = true;
      firewall.allowedTCPPorts = [ 53317 ]; # for LocalSend
    };

    ##############################################################################
    ## WiFi access point for other devices
    ##
    ## The service existsbut isn't started automatically. It can be spawned with
    ## `systemctl start create_ap`.

    services.create_ap = {
      enable = true;
      settings = {
        INTERNET_IFACE = config.x_niols.thisLaptopsWifiInterface;
        WIFI_IFACE = config.x_niols.thisLaptopsWifiInterface;
        SSID = toSentenceCase config.x_niols.thisMachinesName;
        PASSPHRASE = "ReKuYm05"; # FIXME: secret?
        FREQ_BAND = "2.4";
      };
    };
    ## Do not make the unit wanted by anything, such that it will exist but not
    ## start automatically.
    systemd.services.create_ap.wantedBy = mkForce [ ];
  };
}
