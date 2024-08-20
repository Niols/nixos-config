{ config, secrets, ... }:

let
  url = "money.niols.fr";
  dataDir = "/var/lib/firefly-iii";

in {
  services.firefly-iii = {
    enable = true;

    inherit dataDir;

    enableNginx = true;
    virtualHost = url;

    settings = {
      APP_URL = url;
      APP_KEY_FILE = config.age.secrets.firefly-iii-app-key-file.path;
    };
  };

  services.nginx.virtualHosts.${url} = {
    forceSSL = true;
    enableACME = true;
  };

  age.secrets.firefly-iii-app-key-file = {
    file = "${secrets}/firefly-iii-app-key-file.age";
    mode = "600";
    owner = "firefly-iii";
  };

  ## Backup

  services.borgbackup.jobs.money = {
    startAt = "*-*-* 05:00:00";

    paths = [ dataDir ];

    repo = "ssh://u363090@hester.niols.fr:23/./backups/money";
    encryption = {
      mode = "repokey";
      passCommand =
        "cat ${config.age.secrets.hester-firefly-iii-backup-repokey.path}";
    };
    environment.BORG_RSH =
      "ssh -i ${config.age.secrets.hester-firefly-iii-backup-identity.path}";
  };

  age.secrets.hester-firefly-iii-backup-identity.file =
    "${secrets}/hester-firefly-iii-backup-identity.age";
  age.secrets.hester-firefly-iii-backup-repokey.file =
    "${secrets}/hester-firefly-iii-backup-repokey.age";
}
