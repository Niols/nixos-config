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

      ## Telegraf to bridge data betwen MQTT/Mosquitto and PostgreSQL.
      ##
      services.telegraf = {
        enable = true;
        extraConfig = {
          inputs.mqtt_consumer = {
            servers = [ "tcp://localhost:${toString mqttPort}" ];
            username = "telegraf";
            password = "\${MOSQUITTO_PASSWORD}"; # set from secrets, see `environmentFiles` below
            topics = [ "nrg_dongle_pro/all" ];
            data_format = "json_v2";
            json_v2 = [
              {
                measurement_name = "nrg_dongle_pro";
                field = mapAttrsToList (path: type: { inherit path type; }) {
                  current_l1 = "float";
                  current_l2 = "float";
                  current_l3 = "float";
                  electricity_tariff = "float";
                  energy_delivered_tariff1 = "float";
                  energy_delivered_tariff2 = "float";
                  energy_returned_tariff1 = "float";
                  energy_returned_tariff2 = "float";
                  power_delivered = "float";
                  power_delivered_l1 = "float";
                  power_delivered_l2 = "float";
                  power_delivered_l3 = "float";
                  power_returned = "float";
                  power_returned_l1 = "float";
                  power_returned_l2 = "float";
                  power_returned_l3 = "float";
                  timestamp = "string";
                  voltage_l1 = "float";
                  voltage_l2 = "float";
                  voltage_l3 = "float";
                };
              }
            ];
          };
          outputs.prometheus_client = {
            listen = "127.0.0.1:${toString telegrafMetricsPort}";
            expiration_interval = "${toString (1.2 * telegrafScrapeIntervalSeconds)}s"; # more than 1 scrape interval, but less than 2
          };
          outputs.postgresql = { };
        };
        environmentFiles = [ config.age.secrets.telegraf-secrets.path ];
      };

      services.postgresql = {
        ensureDatabases = [ "telegraf" ];
        ensureUsers = [
          {
            name = "telegraf";
            ensureDBOwnership = true;
          }
          {
            name = "grafana";
            # see privileges below
          }
        ];
      };
      systemd.services.postgresql.postStart = lib.mkAfter ''
        psql -tA <<'EOF'
          \set password `cat ${config.age.secrets.postgresql-password-grafana.path}`
          ALTER USER "grafana" WITH PASSWORD :'password';
          GRANT CONNECT ON DATABASE "telegraf" TO "grafana";
          \connect telegraf
          GRANT USAGE ON SCHEMA public TO "grafana";
          GRANT SELECT ON ALL TABLES IN SCHEMA public TO "grafana";
          ALTER DEFAULT PRIVILEGES FOR ROLE "telegraf" IN SCHEMA public
            GRANT SELECT ON TABLES TO "grafana";
        EOF
      '';
      age.secrets.postgresql-password-grafana.owner = "postgres";

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

      services.postgresqlBackup.databases = [ "telegraf" ];

      _common.hester.backupJobs.grafana = {
        paths = [
          "/var/backup/postgresql/telegraf.sql.gz"
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
