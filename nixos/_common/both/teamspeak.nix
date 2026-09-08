{ config, lib, ... }:

let
  inherit (lib) mkMerge mkIf;

in
{
  config = mkMerge [
    (mkIf config.x_niols.services.teamspeak.enabledOnAnyServer {
      x_niols.dnsZoneEntries."niols.fr"."ts" = {
        type = "CNAME";
        value = "${config.x_niols.services.teamspeak.enabledOn}.niols.fr.";
      };
    })

    (mkIf config.x_niols.services.teamspeak.enabledOnThisServer {
      services.teamspeak3 = {
        enable = true;
        openFirewall = true;
        dataDir = "/var/lib/teamspeak";
        logPath = "/var/log/teamspeak";
      };

      ############################################################################
      ## Daily backup
      ##
      ## They have to happen some time after 04:00 so as to include the dump of the
      ## database. See ./databases.nix.

      _common.hester.backupJobs.teamspeak = {
        startAt = "*-*-* 06:00:00";
        paths = [
          "/var/lib/teamspeak"
        ];
        repokeyFile = config.age.secrets.hester-teamspeak-backup-repokey.path;
        identityFile = config.age.secrets.hester-teamspeak-backup-identity.path;
      };
    })
  ];
}
