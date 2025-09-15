{ config, ... }:

{
  services.borgbackup.jobs.git = {
    startAt = "*-*-* 06:00:00";

    paths = [ "/hester/services/git" ];

    repo = "ssh://u363090@hester.niols.fr:23/./backups/git";
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.age.secrets.hester-git-backup-repokey.path}";
    };
    environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-git-backup-identity.path}";
  };

  systemd.services.borgbackup-job-git.unitConfig.RequiresMountsFor = "/hester";

  _common.hester.fileSystems = {
    services-git.path = "/services/git";
  };
}
