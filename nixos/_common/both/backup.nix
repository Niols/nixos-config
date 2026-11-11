{ config, lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) types;
  inherit (lib.attrsets) concatMapAttrs;

  backupJob = {
    options = {
      startAt = mkOption {
        type = types.str;
        default = "daily";
      };
      paths = mkOption { };
      repokeyFile = mkOption { type = types.path; };
      identityFile = mkOption { type = types.path; };
    };
  };

  mkBackupJob =
    name:
    {
      startAt,
      paths,
      repokeyFile,
      identityFile,
    }:
    {
      inherit startAt paths;
      repo = "ssh://u363090@hester.niols.fr:23/./backups/${name}";
      encryption = {
        mode = "repokey";
        passCommand = "cat ${repokeyFile}";
      };
      ## NOTE: We have to disable StrictHostKeyChecking and UserKnownHostsFile
      ## because Hester sometimes gets moved, which causes SSH to ask us whether
      ## we want to add it to the known hosts or not, which in turn causes the
      ## Borgbackup job to fail from that day onwards.
      environment.BORG_RSH = "ssh -i ${identityFile} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    };

in
{
  options.x_niols.backupJobs = mkOption {
    type = types.attrsOf (types.submodule backupJob);
    default = { };
  };

  config.services.borgbackup.jobs = concatMapAttrs (name: job: {
    "x-niols-${name}" = mkBackupJob name job;
  }) config.x_niols.backupJobs;
}
