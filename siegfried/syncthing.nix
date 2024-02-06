{ config, secrets, ... }:

{
  services.syncthing = {
    enable = true;
    user = "syncthing";

    key = config.age.secrets.syncthing-siegfried-key.path;
    cert = config.age.secrets.syncthing-siegfried-cert.path;

    guiAddress = "127.0.0.1:8384";
    settings.gui.insecureSkipHostcheck = true;

    overrideFolders = true;
    settings.folders = {
      Music = {
        path = "/hester/medias/music";
        ignorePerms = true;
        devices = [ "Barbara" "Philippe" "Wallace" ];
      };

      Organiser = {
        path = "/hester/organiser";
        ignorePerms = true;
        devices = [ "Barbara" "Oxana" "Philippe" "Wallace" ];
      };

      MobileSheets = {
        path = "/hester/services/syncthing/MobileSheets";
        ignorePerms = true;
        devices = [ "Barbara" "Philippe" "Oxana" ];
      };

      "Oxana/Documents" = {
        path = "/hester/services/syncthing/Oxana/Documents";
        ignorePerms = true;
        devices = [ "Oxana" "Philippe" "Wallace" ];
      };

      "Oxana/Notes" = {
        path = "/hester/services/syncthing/Oxana/Notes";
        ignorePerms = true;
        devices = [ "Oxana" "Philippe" "Wallace" ];
      };

      "Philippe/DCIM/SD Card" = {
        path = "/hester/services/syncthing/Philippe/DCIM/SD Card";
        ignorePerms = true;
        devices = [ "Philippe" "Wallace" ];
      };

      "Philippe/DCIM/Storage" = {
        path = "/hester/services/syncthing/Philippe/DCIM/Storage";
        ignorePerms = true;
        devices = [ "Philippe" "Wallace" ];
      };

      "Philippe/Movies/Storage" = {
        path = "/hester/services/syncthing/Philippe/Movies/Storage";
        ignorePerms = true;
        devices = [ "Philippe" "Wallace" ];
      };

      "Philippe/Pictures/SD Card" = {
        path = "/hester/services/syncthing/Philippe/Pictures/SD Card";
        ignorePerms = true;
        devices = [ "Philippe" "Wallace" ];
      };

      "Philippe/Pictures/Storage" = {
        path = "/hester/services/syncthing/Philippe/Pictures/Storage";
        ignorePerms = true;
        devices = [ "Philippe" "Wallace" ];
      };

      "Philippe/Scans" = {
        path = "/hester/services/syncthing/Philippe/Scans";
        ignorePerms = true;
        devices = [ "Philippe" "Wallace" ];
      };
    };

    overrideDevices = true;
    settings.devices = {
      "Barbara".id =
        "E7HZWE3-HB34JFR-DQ32B5K-NAUHD24-W7IS5RX-NDCR546-KAKWW5D-BV3Y3Q6";
      "Philippe".id =
        "BJJ7KND-NXILKPP-WLFUWOR-E6SCV6N-WRUN7RE-TUCKN6S-HIHVEF6-EIDI5AS";
      "Siegfried".id =
        "HTWB4DP-OZOHWUQ-726RZSD-77S3TAF-JULJVE5-DCBVE5T-A37LY2L-GFR37AO";
      "Oxana".id =
        "HYNDGWO-FQ7PP2U-EQJUFPR-FSHLZP6-DIU54FU-HBSLUZD-MJDYJFZ-TW5TOQL";
      "Wallace".id =
        "4CGPDOY-WHAWYRZ-OIOF4RN-75UA5QO-JEUBXAA-AWFRAAR-3MTBXFM-IGM3GQG";
    };
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
      basicAuthFile = config.age.secrets.syncthing-siegfried-passwd.path;
    };
  };

  age.secrets.syncthing-siegfried-passwd = {
    file = "${secrets}/syncthing-siegfried-passwd.age";
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  age.secrets.syncthing-siegfried-key.file =
    "${secrets}/syncthing-siegfried-key.age";
  age.secrets.syncthing-siegfried-cert.file =
    "${secrets}/syncthing-siegfried-cert.age";

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
      passCommand =
        "cat ${config.age.secrets.hester-syncthing-backup-repokey.path}";
    };
    environment.BORG_RSH =
      "ssh -i ${config.age.secrets.hester-syncthing-backup-identity.path}";
  };

  systemd.services.borgbackup-job-syncthing.unitConfig.RequiresMountsFor =
    "/hester";

  age.secrets.hester-syncthing-backup-identity.file =
    "${secrets}/hester-syncthing-backup-identity.age";
  age.secrets.hester-syncthing-backup-repokey.file =
    "${secrets}/hester-syncthing-backup-repokey.age";
}
