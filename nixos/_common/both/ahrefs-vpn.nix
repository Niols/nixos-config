{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkMerge;

  makeInterface =
    {
      endpoint,
      mtu ? null,
    }:
    {
      ips = [
        "192.168.45.6/32"
        "fd86:0:45::6/128"
      ];
      privateKeyFile = config.age.secrets.wireguard-ahlaya-ahrefs-key.path;
      peers = [
        {
          publicKey = "J4JjnCIuqMIEKcS98w1OyZnTiSlVQzUTrz8BhV7N3F8=";
          allowedIPs = [
            "192.168.45.1"
            "fd86:0:45::1"
            "5.188.12.0/22"
            "3.120.100.39"
            "13.248.206.194"
            "76.223.89.128"
            "15.197.162.230"
            "3.33.179.158"
            "13.248.243.217"
            "76.223.105.174"
            "61.16.24.0/22"
            "103.150.140.0/23"
            "168.100.128.0/19"
            "202.8.40.0/22"
            "202.94.84.0/23"
            "2001:470:24a::/48"
            "2001:470:3b8::/48"
            "2001:470:3bb::/48"
            "2001:df3:7c80::/48"
            "2401:59a0::/32"
            "104.18.39.141"
            "162.159.140.4"
            "172.64.148.115"
            "172.66.0.4"
            "2606:4700:4404::ac40:9473"
            "2606:4700:7::4"
            "2a06:98c1:3106::6812:278d"
            "2a06:98c1:3122:8000::"
            "2a06:98c1:3123:8000::"
            "2a06:98c1:58::4"
            "8.47.69.0"
            "8.6.112.0"
            "18.193.164.59"
            "44.210.147.40"
          ];
          inherit endpoint;
        }
      ];
      inherit mtu;
    };

  socatProxy = "helga";
  socatPort = 4433;
  socatLocalPort = 51820;

  ahrefsEndpoint = "backend-vpn.ahrefs.net:4433";

in
{
  config = mkMerge [
    (mkIf (config.x_niols.thisMachinesName == "ahlaya") {
      networking.wireguard = {
        enable = true;
        interfaces.ahrefs = makeInterface { endpoint = ahrefsEndpoint; };
      };

      ## Ahrefs's Wireguard gateway uses non-standard port 4433. Standard port,
      ## if needed by another configuration, would be 51820.
      networking.firewall.allowedTCPPorts = [ 4433 ];
      networking.firewall.allowedUDPPorts = [ 4433 ];

      ## Skip asking for password when starting or stopping the Ahrefs VPN unit.
      security.polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (
            action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "wireguard-ahrefs.service" &&
            subject.isInGroup("users")
          ) {
            return polkit.Result.YES;
          }
        });
      '';
    })

    ## Ahrefs's VPN, tunnelled via TCP through one of my servers, to circumvent
    ## VPN protection from my mobile ISP. It gets slow, but at least it works.

    (mkIf (config.x_niols.thisMachinesName == "ahlaya") {
      networking.wireguard.interfaces.ahrefs-tunnelled = makeInterface {
        mtu = 1280; # reduced MTU for TCP overhead
        endpoint = "localhost:${toString socatLocalPort}";
      };

      systemd.services.wireguard-ahrefs-tunnelled = {
        wantedBy = [ ]; # disabled by default (otherwise would be "multi-user.target")
        requires = [ "wireguard-ahrefs-tunnel-client.service" ]; # must have socat
        after = [ "wireguard-ahrefs-tunnel-client.service" ]; # start after socat
        bindsTo = [ "wireguard-ahrefs-tunnel-client.service" ]; # stop if socat stops
        conflicts = [ "wireguard-ahrefs.service" ];
      };
      systemd.services.wireguard-ahrefs.conflicts = [ "wireguard-ahrefs-tunnelled.service" ];

      systemd.services.wireguard-ahrefs-tunnel-client = {
        description = "Socat WireGuard UDP to TCP forwarder";
        wantedBy = [ ]; # disabled by default (otherwise would be "multi-user.target")
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat -d -d -t600 -T600 UDP4-LISTEN:${toString socatLocalPort},reuseaddr,fork TCP4:${socatProxy}.niols.fr:${toString socatPort}";
          Restart = "always";
        };
      };
    })

    (mkIf (config.x_niols.thisMachinesName == socatProxy) {
      systemd.services.wireguard-ahrefs-tunnel-server = {
        description = "Socat WireGuard TCP to UDP forwarder";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat -d -d TCP4-LISTEN:${toString socatPort},reuseaddr,fork UDP4:${ahrefsEndpoint}";
          Restart = "always";
        };
      };
      networking.firewall.allowedTCPPorts = [ socatPort ];
    })
  ];
}
