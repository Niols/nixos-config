{ config, secrets, ... }:

{
  services.borgbackup.jobs.git = {
    startAt = "*-*-* 06:00:00";

    paths = [ "/hester/services/git" ];

    repo = "ssh://u363090@hester.niols.fr:23/./backups/git";
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.age.secrets.hester-git-backup-repokey.path}";
    };
    environment.BORG_RSH =
      "ssh -i ${config.age.secrets.hester-git-backup-identity.path}";
  };

  systemd.services.borgbackup-job-git.unitConfig.RequiresMountsFor = "/hester";

  age.secrets.hester-git-backup-identity.file =
    "${secrets}/hester-git-backup-identity.age";
  age.secrets.hester-git-backup-repokey.file =
    "${secrets}/hester-git-backup-repokey.age";
}
