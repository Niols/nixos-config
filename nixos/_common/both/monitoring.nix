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

  mqttPort = 1883;
  nodeMetricsPort = 9000;
  processMetricsPort = 9256;
  telegrafMetricsPort = 9273;
  telegrafScrapeIntervalSeconds = 10; # must match the publishing interval of the dongles

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
        globalConfig.scrape_interval = "15s";
        retentionTime = "60d";
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
          {
            job_name = "telegraf";
            scrape_interval = "${toString telegrafScrapeIntervalSeconds}s";
            static_configs = [ { targets = [ "localhost:${toString telegrafMetricsPort}" ]; } ];
          }
        ];
        port = prometheusPort;
      };

      ## MQTT broker, to receive messages from IoT devices; in a first instance,
      ## the NRG Dongle Pro.
      services.mosquitto = {
        enable = true;
        logType = [ "all" ]; # FIXME: remove
        listeners = [
          {
            address = "0.0.0.0";
            port = mqttPort;
            users = {
              nrg_dongle_pro = {
                acl = [ "write nrg_dongle_pro/#" ];
                passwordFile = config.age.secrets.mosquitto-password-nrg_dongle_pro.path;
              };
              telegraf = {
                acl = [ "read #" ];
                passwordFile = config.age.secrets.mosquitto-password-telegraf.path;
              };
            };
          }
        ];
      };
      networking.firewall.allowedTCPPorts = [ mqttPort ];

      ## Telegraf to bridge data betwen providers; in a first instance between
      ## MQTT/Mosquitto and Prometheus.
      ##
      ## NOTE[May 2026]: I don't like this so much, because it's weirdly
      ## push-and-pull, as in the dongle pushes MQTT onto Mosquitto, which then
      ## passes to Telegraf, but then Prometheus pulls it, and things can get
      ## desynchronised. A better solution would be for Telegraf to push into a
      ## database, but that would be more work to set up and maintain, and it
      ## isn't my focus at the moment.
      ##
      services.telegraf = {
        enable = true;
        extraConfig = {
          inputs.mqtt_consumer = {
            servers = [ "tcp://localhost:${toString mqttPort}" ];
            username = "telegraf";
            password = "\${MOSQUITTO_PASSWORD}"; # set from secrets, see `environmentFiles` below
            topics = [ "nrg_dongle_pro/#" ];
            data_format = "value";
            data_type = "float";
            name_prefix = "nrg_dongle_pro_"; # works only because we have only one provider
            topic_parsing = [
              {
                topic = "nrg_dongle_pro/+";
                measurement = "_/measurement";
              }
            ];
          };
          outputs.prometheus_client = {
            listen = "127.0.0.1:${toString telegrafMetricsPort}";
            expiration_interval = "${toString (1.2 * telegrafScrapeIntervalSeconds)}s"; # more than 1 scrape interval, but less than 2
          };
        };
        environmentFiles = [ config.age.secrets.telegraf-secrets.path ];
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
      ## Daily backup of Monitoring data
      ##
      ## TODO: Rename.

      _common.hester.backupJobs.grafana = {
        paths = [
          "/var/lib/prometheus2"
          "/var/lib/grafana"
        ];
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
