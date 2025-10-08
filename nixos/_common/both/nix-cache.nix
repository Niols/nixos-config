{ config, lib, ... }:

let
  inherit (lib)
    mkEnableOption
    mkMerge
    mkIf
    ;

  domain = "nix-cache.niols.fr";
  port = 7865;

  ## Grab the user from the configuration. It will be used as user of the
  ## database and name of the database.
  inherit (config.services.atticd) user;

in
{
  options.x_niols.enableNixCache = mkEnableOption {
    description = ''
      Whether to have this machine serve the Nix cache on Hester using Atticd.

      FIXME: We should ensure that only one machine does this.
    '';
  };

  config = mkMerge [
    {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        nix-cache  IN  CNAME  siegfried
      '';
    }

    (mkIf config.x_niols.enableNixCache {
      services.atticd = {
        enable = true;
        mode = "monolithic";
        settings = {
          listen = "[::1]:${toString port}";
          api-endpoint = "https://${domain}/";
          database.url = "postgresql://${user}@localhost/${user}?host=/run/postgresql";
          storage.type = "local";
          storage.path = "/hester/services/atticd";
          garbage-collection.inteval = "24 hours";
          garbage-collection.default-retention-period = "1 month";
        };
        environmentFile = config.age.secrets.atticd-environment.path;
      };

      ## Mount the right folder on Hester with the proper permissions.
      _common.hester.fileSystems.services-atticd = {
        path = "/services/atticd";
        uid = user;
        gid = config.services.atticd.group;
      };

      services.postgresql = {
        ensureDatabases = [ user ];
        ensureUsers = [
          {
            name = user;
            ensureDBOwnership = true;
          }
        ];
      };

      services.nginx.virtualHosts.nix-cache = {
        serverName = domain;
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://[::1]:${toString port}";
          extraConfig = ''
            ## The Atticd upstream can get extremely slow on big store paths, so
            ## we bump the proxy timeouts drastically. This is a bit of a design
            ## flaw on Atticd's side, but this will have to do.
            proxy_connect_timeout 600s;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
          '';
        };
      };

      ## We will be pushing large objects (eg. nextcloud-app-recognize is ~1.4GB),
      ## so we need to bump the `clientMaxBodySize` for those. FIXME: reduce once
      ## Attic knows how to push things in chunks.
      ## See https://github.com/Niols/nixos-config/issues/264
      services.nginx.clientMaxBodySize = "5G";

      ############################################################################
      ## Daily backup
      ##
      ## They have to happen some time after 04:00 so as to include the dump of the
      ## database. See ./databases.nix.
      ##
      ## NOTE: This is “just a cache”, so the backups are not very important.
      ## However, losing the database would cause us to lose all the tokens and
      ## have to redistribute them everywhere, which would be quite annoying.

      services.postgresqlBackup.databases = [ "atticd" ];

      services.borgbackup.jobs.atticd = {
        startAt = "*-*-* 04:30:00";

        paths = [
          "/var/backup/postgresql/atticd.sql.gz"
        ];

        repo = "ssh://u363090@hester.niols.fr:23/./backups/atticd";
        encryption = {
          mode = "repokey";
          passCommand = "cat ${config.age.secrets.hester-atticd-backup-repokey.path}";
        };
        environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-atticd-backup-identity.path}";
      };
    })
  ];
}
