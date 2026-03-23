{ config, lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) types;
  inherit (lib.attrsets) concatMapAttrs;
  inherit (lib.lists) optionals;

  fileSystemOpt = {
    options = {
      path = mkOption {
        description = ''
          Path of the folder to mount within Hester. Must not end in a slash.
          For mounting everything (which is not recommended, except maybe on
          laptops, use "").
        '';
        type = types.str;
      };
      uid = mkOption {
        description = ''
          The user that should own the share.
        '';
        type = types.str;
        default = "root";
      };
      gid = mkOption {
        description = ''
          The group that should own the share.
        '';
        type = types.str;
        default = "hester";
      };
      worldReadable = mkOption {
        description = ''
          Whether to make the share readable to “other” users. It is always
          readable and writable by the user and the group.
        '';
        type = types.bool;
        default = false;
      };
    };
  };

  mkHesterFileSystem =
    {
      path,
      uid,
      gid,
      worldReadable,
    }:
    {
      mountPoint = "/hester" + path;
      device = "//hester.niols.fr/backup" + path;
      fsType = "cifs";
      options = [
        "_netdev"
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
        "credentials=${config.age.secrets.hester-samba-credentials.path}"
        "uid=${uid}"
        "gid=${gid}"
        "dir_mode=${if worldReadable then "0775" else "0770"}"
        "file_mode=${if worldReadable then "0664" else "0660"}"

        ## Symbolic link support on a CIFS share.
        "mfsymlinks"
      ];
    };

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

  mkHesterBackupJob =
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
  options = {
    _common.hester = {
      fileSystems = mkOption {
        type = types.attrsOf (types.submodule fileSystemOpt);
        default = { };
      };

      backupJobs = mkOption {
        type = types.attrsOf (types.submodule backupJob);
        default = { };
      };
    };
  };

  config = {
    fileSystems = concatMapAttrs (name: fs: {
      "hester-${name}" = mkHesterFileSystem fs;
    }) config._common.hester.fileSystems;

    users.groups.hester.members =
      optionals config.x_niols.enableNiolsUser [ "niols" ]
      ++ optionals config.x_niols.enableWorkUser [ "work" ];

    services.borgbackup.jobs = concatMapAttrs (name: job: {
      "hester-${name}" = mkHesterBackupJob name job;
    }) config._common.hester.backupJobs;
  };
}
