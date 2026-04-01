{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkMerge;

  wgPublicKey = "J4JjnCIuqMIEKcS98w1OyZnTiSlVQzUTrz8BhV7N3F8=";
  ahrefsEndpoint = "backend-vpn.ahrefs.net:4433";

  ## wstunnel tunnel settings
  tunnelDomain = "ahrefs-vpn-tunnel.niols.fr";
  tunnelLocalPort = 51820;
  wstunnelInternalPort = 8443;

  inherit (config.x_niols.services) ahrefs-vpn-tunnel;

in
{
  config = mkMerge [
    (mkIf (config.x_niols.thisMachinesName == "ahlaya") {
      networking.wireguard = {
        enable = true;
        interfaces.ahrefs = {
          ips = [
            "192.168.45.6/32"
            "fd86:0:45::6/128"
          ];
          privateKeyFile = config.age.secrets.wireguard-ahlaya-ahrefs-key.path;
          ## Reduced MTU for tunnel compatibility. The penalty is negligible and
          ## it avoids having to change MTU when switching between direct and
          ## tunnelled modes.
          mtu = 1280;
          peers = [
            {
              publicKey = wgPublicKey;
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
              ## Default to tunnelled mode via wstunnel. Use `sudo
              ## ahrefs-vpn-direct` to switch to a direct connection.
              endpoint = "127.0.0.1:${toString tunnelLocalPort}";
            }
          ];
        };
      };

      ## wstunnel client for tunnelled mode. Started automatically and WireGuard
      ## is ordered after it so the tunnel is ready when WireGuard comes up.
      services.wstunnel = {
        enable = true;
        clients.ahrefs-vpn = {
          enable = true;
          autoStart = true;
          connectTo = "wss://${tunnelDomain}:443";
          settings = {
            local-to-remote = [
              "udp://127.0.0.1:${toString tunnelLocalPort}:${ahrefsEndpoint}"
            ];
          };
        };
      };

      ## Ensure WireGuard starts after wstunnel so the local UDP endpoint is
      ## ready when WireGuard tries to send its first handshake.
      systemd.services.wireguard-ahrefs = {
        after = [ "wstunnel-client-ahrefs-vpn.service" ];
        wants = [ "wstunnel-client-ahrefs-vpn.service" ];
      };

      ## Helper scripts to switch between direct and tunnelled VPN modes. Usage:
      ##
      ##   sudo ahrefs-vpn-direct      # use direct connection
      ##   sudo ahrefs-vpn-tunnelled   # use wstunnel via tunnel server
      ##
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "ahrefs-vpn-direct" ''
          set -euo pipefail
          systemctl stop wstunnel-client-ahrefs-vpn.service 2>/dev/null || true
          ${pkgs.wireguard-tools}/bin/wg set ahrefs peer ${wgPublicKey} endpoint ${ahrefsEndpoint}
          echo "Switched Ahrefs VPN to direct mode."
        '')
        (pkgs.writeShellScriptBin "ahrefs-vpn-tunnelled" ''
          set -euo pipefail
          systemctl start wstunnel-client-ahrefs-vpn.service
          sleep 1
          ${pkgs.wireguard-tools}/bin/wg set ahrefs peer ${wgPublicKey} endpoint 127.0.0.1:${toString tunnelLocalPort}
          echo "Switched Ahrefs VPN to tunnelled mode."
        '')
      ];

      ## Skip asking for password when managing the Ahrefs VPN and tunnel units.
      security.polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (
            action.id == "org.freedesktop.systemd1.manage-units" &&
            (
              action.lookup("unit") == "wireguard-ahrefs.service" ||
              action.lookup("unit") == "wstunnel-client-ahrefs-vpn.service"
            ) &&
            subject.isInGroup("users")
          ) {
            return polkit.Result.YES;
          }
        });
      '';
    })

    ## DNS entry for the wstunnel tunnel domain.
    (mkIf ahrefs-vpn-tunnel.enabledOnAnyServer {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        ahrefs-vpn-tunnel  IN  CNAME  ${ahrefs-vpn-tunnel.enabledOn}
      '';
    })

    ## wstunnel server, behind nginx. Relays WebSocket traffic to the Ahrefs
    ## WireGuard endpoint over UDP.
    (mkIf ahrefs-vpn-tunnel.enabledOnThisServer {
      services.wstunnel = {
        enable = true;
        servers.ahrefs-vpn = {
          enable = true;
          listen = {
            host = "127.0.0.1";
            port = wstunnelInternalPort;
            enableHTTPS = false;
          };
          settings.restrict-to = [
            {
              host = "backend-vpn.ahrefs.net";
              port = 4433;
            }
          ];
        };
      };

      services.nginx.virtualHosts.${tunnelDomain} = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString wstunnelInternalPort}";
          proxyWebsockets = true;
          ## Prevent nginx from closing idle WebSocket connections too early.
          extraConfig = ''
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
          '';
        };
      };

    })
  ];
}
