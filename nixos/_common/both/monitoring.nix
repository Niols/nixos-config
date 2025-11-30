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
    optionalString
    ;

  metricsPort = 9000;

  ## The Prometheus port is entered manually into Grafana.
  prometheusPort = 9090;

  monitorServer = machines.servers.${config.x_niols.services.monitor.enabledOn};

in
{
  config = mkMerge [

    ## Each server exports its metrics.
    (mkIf config.x_niols.isServer {
      services.prometheus.exporters.node = {
        enable = true;
        port = metricsPort;
      };

      ## Only allow the monitoring server to scrape metrics.
      networking.firewall.extraCommands = ''
        ${optionalString (monitorServer ? ipv4) ''
          iptables -A nixos-fw -p tcp --dport ${toString metricsPort} -s ${monitorServer.ipv4} -j nixos-fw-accept
        ''}
        ${optionalString (monitorServer ? ipv6) ''
          ip6tables -A nixos-fw -p tcp --dport ${toString metricsPort} -s ${monitorServer.ipv6} -j nixos-fw-accept
        ''}
      '';
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
          {
            job_name = "dancelor";
            scheme = "https";
            static_configs = [
              {
                targets = [ "dancelor.org" ];
              }
            ];
            scrape_interval = "1m";
            metrics_path = "/api/metrics";
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

      ############################################################################
      ## Daily backup of Grafana
      ##
      ## There is no need backing up Prometheus or the node exporters; if things
      ## crash and we lose our monitoring data, it isn't a big deal. Grafana,
      ## however, will store the dashboards and everything, and that is fairly
      ## important.

      services.borgbackup.jobs.grafana = {
        startAt = "daily";

        paths = [
          "/var/lib/grafana"
        ];

        repo = "ssh://u363090@hester.niols.fr:23/./backups/grafana";
        encryption = {
          mode = "repokey";
          passCommand = "cat ${config.age.secrets.hester-grafana-backup-repokey.path}";
        };
        environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-grafana-backup-identity.path}";
      };

      age.secrets = {
        hester-grafana-backup-identity.mode = "600";
        hester-grafana-backup-repokey.mode = "600";
      };
    })
  ];
}
