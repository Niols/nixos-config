{
  flake.nixosModules.ahlaya =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    {
      imports = [
        _common/laptop.nix

        ## Specific hardware optimisations for Lenovo ThinkPad X1 13th gen
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-13th-gen
      ];

      x_niols.thisMachinesName = "ahlaya";
      x_niols.thisLaptopsWifiInterface = "wlp0s20f3";
      disko.devices.disk.main.device = "/dev/nvme0n1";
      nixpkgs.hostPlatform = "x86_64-linux";
      services.autorandr.x_niols.thisLaptopsFingerprint = "00ffffffffffff0009e5ca0c0000000003220104a51e1378078b94a3564d9b240d515400000001010101010101010101010101010101333f80dc70b03c40302036002ebc1000001a000000fd00283c4c4c10010a202020202020000000fe00424f452043510a202020202020000000fc004e4531343057554d2d4e364d0a018d7020790200250109f77702f77702283c80810015741a00000301283c00006a496a493c000000008d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b790";
      x_niols.enableWorkUser = true;

      home-manager.users.niols.imports = [ ../home ];
      home-manager.users.work = {
        imports = [ ../home ];
        x_niols.isWork = true;
      };

      _common.hester.fileSystems.root.path = "";

      ##############################################################################
      ## Ahrefs VPN

      networking.wireguard = {
        enable = true;
        interfaces = {
          ahrefs = {
            mtu = 1280; # Important: reduced MTU for TCP overhead
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
                # endpoint = "backend-vpn.ahrefs.net:4433";
                endpoint = "127.0.0.1:51820"; # Points to local socat
              }
            ];
          };
        };
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

      systemd.services.wg-socat-client = {
        description = "Socat WireGuard UDP to TCP forwarder";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat -d -d -t600 -T600 UDP4-LISTEN:51820,reuseaddr,fork TCP4:helga.niols.fr:4433";
          Restart = "always";
        };
      };
    };
}
