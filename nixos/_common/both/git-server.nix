{ config, lib, ... }:

let
  inherit (lib) mkIf;

in
{
  config = mkIf config.x_niols.services.git.enabledOnThisServer {
    _common.hester.backupJobs.git = {
      startAt = "*-*-* 06:00:00";
      paths = [ "/hester/services/git" ];
      repokeyFile = config.age.secrets.hester-git-backup-repokey.path;
      identityFile = config.age.secrets.hester-git-backup-identity.path;
    };
    systemd.services.borgbackup-job-hester-git.unitConfig.RequiresMountsFor = "/hester";

    _common.hester.fileSystems = {
      services-git.path = "/services/git";
    };
  };
}
