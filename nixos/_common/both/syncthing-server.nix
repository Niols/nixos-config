{ config, lib, ... }:

let
  inherit (lib) mkMerge mkIf;

  guiPort = 8384;

in
{
  config = mkMerge [
    (mkIf config.x_niols.services.syncthing.enabledOnAnyServer {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        syncthing  IN  CNAME  ${config.x_niols.services.syncthing.enabledOn}
      '';
    })

    (mkIf config.x_niols.services.syncthing.enabledOnThisServer {
      services.syncthing = {
        enable = true;
        user = "syncthing";

        key = config.age.secrets.syncthing-server-key.path;
        cert = config.age.secrets.syncthing-server-cert.path;

        guiAddress = "127.0.0.1:${toString guiPort}";
        settings.gui.insecureSkipHostcheck = true;

        x_niols = {
          enableCommonFoldersAndDevices = true;
          thisDevice = "Server";
          defaultFolderPrefix = "/data/services/syncthing";
          extraDefaultFolderConfig.ignorePerms = true;
        };

        settings.folders.Music.path = "/data/medias/music";
        settings.folders.Scottish-ish.path = "/data/medias/scottish-ish";
      };

      services.nginx.virtualHosts.syncthing = {
        serverName = "syncthing.niols.fr";

        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString guiPort}";
          basicAuthFile = config.age.secrets."syncthing-server-passwd".path;
        };
      };

      age.secrets."syncthing-server-passwd" = {
        mode = "600";
        owner = "nginx";
        group = "nginx";
      };

      ############################################################################
      ## Daily backup
      ##
      ## Syncing is not backing up, so we call a Borg job on all of
      ## /data/services/syncthing.

      _common.hester.backupJobs.syncthing = {
        startAt = "*-*-* 06:00:00";
        paths = [ "/data/services/syncthing" ];
        repokeyFile = config.age.secrets.hester-syncthing-backup-repokey.path;
        identityFile = config.age.secrets.hester-syncthing-backup-identity.path;
      };
    })
  ];
}
