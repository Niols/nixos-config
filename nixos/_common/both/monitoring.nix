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

  nodeMetricsPort = 9000;
  processMetricsPort = 9256;

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
        port = nodeMetricsPort;
        enabledCollectors = [ "systemd" ];
      };

      services.prometheus.exporters.process = {
        enable = true;
        port = processMetricsPort;
        settings.process_names = [
          ## Remove nix store path from process name.
          {
            name = "{{.Matches.Wrapped}} {{.Matches.Args}}";
            cmdline = [ "^/nix/store[^ ]*/(?P<Wrapped>[^ /]*) (?P<Args>.*)" ];
          }
          ## Fall back to the binary name for non-nix processes.
          {
            name = "{{.Comm}}";
            cmdline = [ ".+" ];
          }
        ];
      };

      ## Only allow the monitoring server to scrape metrics.
      networking.firewall.extraCommands = ''
        ${optionalString (monitorServer ? ipv4) ''
          iptables -A nixos-fw -p tcp --dport ${toString nodeMetricsPort} -s ${monitorServer.ipv4} -j nixos-fw-accept
          iptables -A nixos-fw -p tcp --dport ${toString processMetricsPort} -s ${monitorServer.ipv4} -j nixos-fw-accept
        ''}
        ${optionalString (monitorServer ? ipv6) ''
          ip6tables -A nixos-fw -p tcp --dport ${toString nodeMetricsPort} -s ${monitorServer.ipv6} -j nixos-fw-accept
          ip6tables -A nixos-fw -p tcp --dport ${toString processMetricsPort} -s ${monitorServer.ipv6} -j nixos-fw-accept
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
            static_configs = mapAttrsToList (server: _: {
              targets = [ "${server}.niols.fr:${toString nodeMetricsPort}" ];
              labels = { inherit server; };
            }) machines.servers;
          }
          {
            job_name = "process";
            static_configs = mapAttrsToList (server: _: {
              targets = [ "${server}.niols.fr:${toString processMetricsPort}" ];
              labels = { inherit server; };
            }) machines.servers;
          }
        ];
        port = prometheusPort;
      };

      ## NOTE: Grafana supports variable expansion with $__file{path} syntax to
      ## read secrets from files instead of storing them in the config. See:
      ## https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#variable-expansion
      services.grafana = {
        enable = true;
        settings = {
          server.domain = "monitor.niols.fr";
          server.root_url = "https://${config.services.grafana.settings.server.domain}/";
          security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}"; # see NOTE above

          smtp = {
            enabled = true;
            host = "mail.infomaniak.com:465";
            user = "no-reply@niols.fr";
            password = "$__file{${config.age.secrets.no-reply-smtp-password.path}}"; # see NOTE above
            from_address = "no-reply@niols.fr";
            from_name = "Grafana";
          };
        };
      };

      services.nginx.virtualHosts.${config.services.grafana.settings.server.domain} = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.grafana.settings.server.http_port}";
          recommendedProxySettings = true;
        };

        ## Grafana Live WebSocket connections require special handling.
        ## See: https://grafana.com/tutorials/run-grafana-behind-a-proxy/
        locations."/api/live/" = {
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

      _common.hester.backupJobs.grafana = {
        paths = [ "/var/lib/grafana" ];
        repokeyFile = config.age.secrets.hester-grafana-backup-repokey.path;
        identityFile = config.age.secrets.hester-grafana-backup-identity.path;
      };

      age.secrets = {
        no-reply-smtp-password = {
          mode = "400";
          owner = "grafana";
          group = "grafana";
        };
        grafana-secret-key = {
          mode = "400";
          owner = "grafana";
          group = "grafana";
        };
        hester-grafana-backup-identity.mode = "600";
        hester-grafana-backup-repokey.mode = "600";
      };
    })
  ];
}
