{ config, secrets, ... }:

{
  services.nginx.virtualHosts."niols.fr" = {
    serverName = "niols.fr";
    serverAliases =
      [ "www.niols.fr" "nicolas.jeannerod.fr" "www.nicolas.jeannerod.fr" ];

    forceSSL = true;
    enableACME = true;

    root = "/hester/services/web/niols.fr";
    locations."/" = {
      index = "index.html";
      tryFiles = "$uri $uri/ =404";
    };
  };

  systemd.services.nginx.unitConfig = {
    requires = [ "hester.automount" ];
    after = [ "hester.automount" ];
  };

  ############################################################################
  ## Daily backup

  services.borgbackup.jobs.web = {
    startAt = "*-*-* 05:00:00";

    paths = [ "/hester/services/web" ];

    repo = "ssh://u363090@hester.niols.fr:23/./backups/web";
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.age.secrets.hester-web-backup-repokey.path}";
    };
    environment.BORG_RSH =
      "ssh -i ${config.age.secrets.hester-web-backup-identity.path}";
  };

  systemd.services.borgbackup-job-web.unitConfig.RequiresMountsFor = "/hester";

  age.secrets.hester-web-backup-identity.file =
    "${secrets}/hester-web-backup-identity.age";
  age.secrets.hester-web-backup-repokey.file =
    "${secrets}/hester-web-backup-repokey.age";
}
