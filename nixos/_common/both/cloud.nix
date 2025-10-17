{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkMerge mkIf;

  hostName = "cloud.niols.fr";
  otherHostNames = [ "cloud.jeannerod.fr" ];

in
{
  config = mkMerge [
    (mkIf config.x_niols.services.cloud.enabledOnAnyServer {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        cloud  IN  CNAME  ${config.x_niols.services.cloud.enabledOn}
      '';
      services.bind.x_niols.zoneEntries."jeannerod.fr" = ''
        cloud  IN  CNAME  cloud.niols.fr.
      '';
    })

    (mkIf config.x_niols.services.cloud.enabledOnThisServer {
      services.nextcloud = {
        enable = true;

        ## #####  Upgrading Nextcloud's version  ###################################
        ##
        ## From https://nixos.wiki/wiki/Nextcloud#Maintenance
        ##
        ## There is no default `nextcloud` package. Instead you have to set the
        ## current version in `services.nextcloud.package`. As soon a major version
        ## of Nextcloud gets unsupported, it will be removed from nixpkgs as well.
        ##
        ## Upgrading then consists of these steps:
        ##
        ## - Increment the version of services.nextcloud.package in your config by 1
        ##   (leaving out a major version is not supported)
        ##
        ## - `nixos-rebuild switch`
        ##
        ## In theory, your Nextcloud has now been upgraded by one version. NixOS
        ## attempts `nextcloud-occ upgrade`, if this succeeds without problems you
        ## don't need to do anything. Check `journalctl` to make sure nothing
        ## horrible happened. Go to the `/settings/admin/overview` page in your
        ## Nextcloud to see whether it recommends further processing, such as
        ## database reindexing or conversion.
        ##
        package = pkgs.nextcloud31;

        inherit hostName;
        settings.trusted_domains = otherHostNames;

        home = "/var/lib/nextcloud";
        datadir = "/var/lib/nextcloud";

        https = true; # use HTTPS for links

        ## Specify important apps via Nix. One can still install apps via the web
        ## interface. The latter get updated automatically.
        extraAppsEnable = true;
        extraApps = with config.services.nextcloud.package.packages.apps; {
          inherit
            calendar
            contacts
            cookbook
            impersonate
            news
            previewgenerator
            quota_warning
            recognize
            tasks
            ;
          ## FIXME: set up onlyoffice
        };
        appstoreEnable = true;
        autoUpdateApps.enable = true;

        configureRedis = true;

        secretFile = config.age.secrets.niolscloud-secrets.path;

        config = {
          adminuser = "admin";
          adminpassFile = config.age.secrets.niolscloud-admin-password.path;

          dbtype = "pgsql";
          dbuser = "nextcloud";
          dbhost = "/run/postgresql";
          dbname = "nextcloud";
        };

        settings = {
          default_phone_region = "FR";

          ## Resource-intensive maintenance tasks are scheduled to run at night,
          ## between 1 and 5.
          maintenance_window_start = 1;

          ## The `file` log type allows reading logs from the NextCloud interface.
          ## REVIEW: One of these two must probably be useless?
          logType = "file";
          log_type = "file";

          ## Mail configuration
          mail_sendmailmode = "smtp";
          mail_from_address = "no-reply";
          mail_domain = "niols.fr";

          ## Mail authentication - password in secrets.
          mail_smtpmode = "smtp";
          mail_smtphost = "mail.infomaniak.com";
          mail_smtpsecure = "ssl";
          mail_smtpport = 465;
          mail_smtpauth = 1;
          mail_smtpname = "no-reply@niols.fr";
        };

        ## Options for the PHP worker. Extension `smbclient` is necessary for CIFS
        ## external storage. Options `opcache.<whatever>` need to be quoted to have
        ## a dot in the name of the option.
        phpExtraExtensions = p: [ p.smbclient ];
        phpOptions."opcache.interned_strings_buffer" = "16";
      };

      age.secrets = {
        niolscloud-admin-password = {
          mode = "640";
          owner = "nextcloud";
          group = "nextcloud";
        };
        niolscloud-secrets = {
          mode = "640";
          owner = "nextcloud";
          group = "nextcloud";
        };
      };

      services.postgresql = {
        ensureDatabases = [ "nextcloud" ];
        ensureUsers = [
          {
            name = "nextcloud";
            ensureDBOwnership = true;
          }
        ];
        ## All databases are backed up daily. See `databases.nix`.
      };

      ## Make sure Nextcloud only starts once the database is up.
      systemd.services."nextcloud-setup" = {
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
      };

      services.nginx.virtualHosts.${hostName} = {
        forceSSL = true;
        enableACME = true;
        serverAliases = otherHostNames;
      };

      ############################################################################
      ## Daily backup
      ##
      ## They have to happen some time after 04:00 so as to include the dump of the
      ## database. See ./databases.nix.

      services.postgresqlBackup.databases = [ "nextcloud" ];

      services.borgbackup.jobs.nextcloud = {
        startAt = "*-*-* 04:15:00";

        paths = [
          "/var/lib/nextcloud"
          "/var/backup/postgresql/nextcloud.sql.gz"
        ];

        repo = "ssh://u363090@hester.niols.fr:23/./backups/nextcloud";
        encryption = {
          mode = "repokey";
          passCommand = "cat ${config.age.secrets.hester-niolscloud-backup-repokey.path}";
        };
        environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-niolscloud-backup-identity.path}";
      };
    })
  ];
}
