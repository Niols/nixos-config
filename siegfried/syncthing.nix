{ config, secrets, ... }:

{
  services.syncthing = {
    enable = true;
    user = "syncthing";

    key = config.age.secrets."syncthing-${config.x_niols.thisDevicesNameLower}-key".path;
    cert = config.age.secrets."syncthing-${config.x_niols.thisDevicesNameLower}-cert".path;

    guiAddress = "127.0.0.1:8384";
    settings.gui.insecureSkipHostcheck = true;

    x_niols = {
      enableCommonFoldersAndDevices = true;
      thisDevice = config.x_niols.thisDevicesName;
      defaultFolderPrefix = "/hester/services/syncthing";
      extraDefaultFolderConfig.ignorePerms = true;
    };

    settings.folders = {
      Organiser.path = "/hester/organiser";
      Music.path = "/hester/medias/music";
    };

    ## REVIEW: Should I override settings.devices.siegfried.addresses? Will it
    ## break? I expect not but who knows.
  };

  users.groups.hester.members = [ "syncthing" ];

  ## Hester is an auto-mountable Samba target with a timeout. If we use
  ## `RequiresMountsFor = "/hester"`, then Syncthing will add a `requires =` and
  ## an `after =` on `hester.mount` which shuts down every time Hester has a
  ## timeout, which is not what we want.
  systemd.services.syncthing-init.unitConfig = {
    requires = [ "hester.automount" ];
    after = [ "hester.automount" ];
  };
  systemd.services.syncthing.unitConfig = {
    requires = [ "hester.automount" ];
    after = [ "hester.automount" ];
  };

  services.nginx.virtualHosts.syncthing = {
    serverName = "syncthing.niols.fr";

    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8384";
      basicAuthFile = config.age.secrets."syncthing-${config.x_niols.thisDevicesNameLower}-passwd".path;
    };
  };

  age.secrets."syncthing-${config.x_niols.thisDevicesNameLower}-passwd" = {
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  _common.hester.fileSystems = {
    medias-music.path = "/medias/music";
    organiser.path = "/organiser";
    services-syncthing.path = "/services/syncthing";
  };

  ############################################################################
  ## Daily backup
  ##
  ## Syncing is not backing up, so we call a Borg job on all of
  ## /hester/services/syncthing.
  ##
  ## - It feels a bit silly to backup Hester on Hester, but the snapshot system
  ##   of Hetzner only allows restoring a snapshot and not exploring it to
  ##   select what to take so I would rather not rely on it.
  ##
  ## - It also feels silly to use an SSH-based `repo` argument to the Borgbackup
  ##   job when we need to have Hester mounted anyways, but this avoids making
  ##   an exception of tihs Borgbackup job. They should all look alike.

  services.borgbackup.jobs.syncthing = {
    startAt = "*-*-* 06:00:00";

    paths = [ "/hester/services/syncthing" ];

    repo = "ssh://u363090@hester.niols.fr:23/./backups/syncthing";
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.age.secrets.hester-syncthing-backup-repokey.path}";
    };
    environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-syncthing-backup-identity.path}";
  };

  systemd.services.borgbackup-job-syncthing.unitConfig.RequiresMountsFor = "/hester";
}
