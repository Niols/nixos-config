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

      ## Systemd oneshot services for switching between VPN modes. These run as
      ## root (for `wg set`) and are managed via polkit, so no sudo is needed.
      systemd.services.ahrefs-vpn-switch-direct = {
        description = "Switch Ahrefs VPN to direct mode";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "ahrefs-vpn-switch-direct" ''
            systemctl stop wstunnel-client-ahrefs-vpn.service 2>/dev/null || true
            ${pkgs.wireguard-tools}/bin/wg set ahrefs peer ${wgPublicKey} endpoint ${ahrefsEndpoint}
          '';
        };
      };

      systemd.services.ahrefs-vpn-switch-tunnel = {
        description = "Switch Ahrefs VPN to tunnelled mode";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "ahrefs-vpn-switch-tunnel" ''
            systemctl start wstunnel-client-ahrefs-vpn.service
            sleep 1
            ${pkgs.wireguard-tools}/bin/wg set ahrefs peer ${wgPublicKey} endpoint 127.0.0.1:${toString tunnelLocalPort}
          '';
        };
      };

      ## Allow `wg show ahrefs` without password so the status script can check
      ## the actual WireGuard endpoint.
      security.sudo.extraRules = [
        {
          groups = [ "users" ];
          commands = [
            {
              command = "${pkgs.wireguard-tools}/bin/wg show ahrefs endpoints";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      ## Helper scripts for switching modes and checking status.
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "ahrefs-vpn-direct" ''
          exec systemctl start ahrefs-vpn-switch-direct.service
        '')
        (pkgs.writeShellScriptBin "ahrefs-vpn-tunnelled" ''
          exec systemctl start ahrefs-vpn-switch-tunnel.service
        '')
        (pkgs.writeShellScriptBin "ahrefs-vpn-status" ''
          case ''${1-} in
            ""|--i3block) ;;
            *)
              echo "Usage: ahrefs-vpn-status [--i3block]" >&2
              exit 1
              ;;
          esac

          wg_active=false
          wstunnel_active=false
          wg_uses_tunnel=false
          endpoint="(none)"

          systemctl is-active --quiet wireguard-ahrefs.service && wg_active=true
          systemctl is-active --quiet wstunnel-client-ahrefs-vpn.service && wstunnel_active=true

          if $wg_active; then
            endpoint=$(sudo ${pkgs.wireguard-tools}/bin/wg show ahrefs endpoints 2>/dev/null \
              | ${pkgs.gawk}/bin/awk '{print $2}')
            case "$endpoint" in
              127.0.0.1:${toString tunnelLocalPort}) wg_uses_tunnel=true ;;
            esac
          fi

          case $wg_active,$wstunnel_active,$wg_uses_tunnel in
            false,*,*)        mode=down ;;
            true,true,true)   mode=tunnel ;;
            true,false,false) mode=direct ;;
            *)                mode=unknown ;;
          esac

          case ''${1-} in
            --i3block)
              case $mode in
                down|unknown) state=Critical ;;
                *)            state=Good ;;
              esac
              echo "{\"text\":\"Ahrefs VPN: $mode\",\"state\":\"$state\"}"
              ;;
            *)
              echo "wireguard is: $($wg_active && echo active || echo inactive)"
              echo "wstunnel is: $($wstunnel_active && echo active || echo inactive)"
              echo "wireguard endpoint is: $endpoint"
              echo "detected mode is: $mode"
              ;;
          esac
        '')
        (pkgs.writeShellScriptBin "ahrefs-vpn-cycle" ''
          if ! systemctl is-active --quiet wireguard-ahrefs.service; then
            systemctl start wireguard-ahrefs.service
          elif systemctl is-active --quiet wstunnel-client-ahrefs-vpn.service; then
            systemctl start ahrefs-vpn-switch-direct.service
          else
            systemctl stop wireguard-ahrefs.service
          fi
        '')
      ];

      ## Skip asking for password when managing Ahrefs VPN-related units.
      security.polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (
            action.id == "org.freedesktop.systemd1.manage-units" &&
            [
              "wireguard-ahrefs.service",
              "wstunnel-client-ahrefs-vpn.service",
              "ahrefs-vpn-switch-direct.service",
              "ahrefs-vpn-switch-tunnel.service"
            ].indexOf(action.lookup("unit")) >= 0 &&
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
