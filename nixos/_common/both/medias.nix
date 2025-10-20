{ config, lib, ... }:

let
  inherit (lib) mkMerge mkIf;

in
{
  config = mkMerge [
    (mkIf config.x_niols.services.medias.enabledOnAnyServer {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        medias  IN  CNAME  ${config.x_niols.services.medias.enabledOn}
      '';
    })

    (mkIf config.x_niols.services.medias.enabledOnThisServer {
      services.jellyfin = {
        enable = true;
        openFirewall = false;
      };

      services.nginx.virtualHosts.medias = {
        serverName = "medias.niols.fr";
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
        };
      };

      users.groups.hester.members = [ "jellyfin" ];

      ############################################################################
      ## Daily backup

      services.borgbackup.jobs.jellyfin = {
        startAt = "*-*-* 06:00:00";

        ## REVIEW: I'm afraid this might be a lot. Review this at some point in the
        ## future to see if some folders should be excluded.
        paths = [ "/var/lib/jellyfin" ];

        repo = "ssh://u363090@hester.niols.fr:23/./backups/jellyfin";
        encryption = {
          mode = "repokey";
          passCommand = "cat ${config.age.secrets.hester-jellyfin-backup-repokey.path}";
        };
        environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-jellyfin-backup-identity.path}";
      };
    })

  ];
}
