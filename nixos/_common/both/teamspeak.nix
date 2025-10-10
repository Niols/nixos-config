{ config, lib, ... }:

let
  inherit (lib) mkMerge mkIf;

in
{
  config = mkMerge [
    (mkIf config.x_niols.services.teamspeak.enabledOnAnyServer {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        ts  IN  CNAME  ${config.x_niols.services.teamspeak.enabledOn};
      '';
      ## FIXME: Also handle niols.net with our DNS server.
      # services.bind.x_niols.zoneEntries."niols.net" = ''
      #   ts  IN  CNAME  ts.niols.fr.
      # '';
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

      services.borgbackup.jobs.teamspeak = {
        startAt = "*-*-* 06:00:00";

        paths = [
          "/var/lib/teamspeak"
        ];

        repo = "ssh://u363090@hester.niols.fr:23/./backups/teamspeak";
        encryption = {
          mode = "repokey";
          passCommand = "cat ${config.age.secrets.hester-teamspeak-backup-repokey.path}";
        };
        environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-teamspeak-backup-identity.path}";
      };
    })
  ];
}
