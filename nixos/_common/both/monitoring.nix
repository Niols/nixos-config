{
  config,
  lib,
  machines,
  ...
}:

let
  inherit (lib)
    mapAttrsToList
    mkMerge
    mkIf
    ;

  metricsPort = 9000;

  ## The Prometheus port is entered manually into Grafana.
  prometheusPort = 9090;

in
{
  config = mkMerge [

    ## Each server exports its metrics.
    (mkIf config.x_niols.isServer {
      services.prometheus.exporters.node = {
        enable = true;
        port = metricsPort;
      };
      networking.firewall.allowedTCPPorts = [ metricsPort ];
    })

    (mkIf config.x_niols.services.monitor.enabledOnAnyServer {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        monitor  IN  CNAME  ${config.x_niols.services.monitor.enabledOn}
      '';
    })

    (mkIf config.x_niols.services.monitor.enabledOnThisServer {
      services.prometheus = {
        enable = true;
        globalConfig.scrape_interval = "1m";
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = mapAttrsToList (server: meta: {
              targets = [ "${meta.ipv4 or meta.ipv6}:${toString metricsPort}" ];
              labels = { inherit server; };
            }) machines.servers;
          }
        ];
        port = prometheusPort;
      };

      services.grafana = {
        enable = true;
        settings = {
          server.domain = "monitor.niols.fr";
          server.root_url = "https://${config.services.grafana.settings.server.domain}/";
        };
      };

      services.nginx.virtualHosts.${config.services.grafana.settings.server.domain} = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
      };
    })
  ];
}
