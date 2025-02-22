{ config, ... }:

{
  services.galene = {
    enable = true;
    insecure = true; # because behind nginx
    httpAddress = "";
    recordingsDir = "/hester/services/galene/recordings";
  };

  _common.hester.fileSystems.services-galene = {
    path = "/services/galene";
    uid = config.services.galene.user;
    gid = config.services.galene.group;
  };

  ############################################################################
  ## Backups

  services.borgbackup.jobs.galene = {
    paths = config.services.galene.stateDir;
    repo = "ssh://u363090@hester.niols.fr:23/./backups/galene";
    startAt = "*-*-* 06:00:00";
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.age.secrets.hester-galene-backup-repokey.path}";
    };
    environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-galene-backup-identity.path}";
  };
}
