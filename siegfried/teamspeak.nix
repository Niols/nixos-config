{ pkgs, ... }:

{
  services.teamspeak3 = {
    enable = true;
    openFirewall = true;
    dataDir = "/var/lib/teamspeak";
    logPath = "/var/log/teamspeak";
  };

  nixpkgs.config.allowUnfreePredicate =
    (pkg: builtins.elem (pkgs.lib.getName pkg) [ "teamspeak-server" ]);

  services.borgbackup.jobs.teamspeak = {
    paths = "/var/lib/teamspeak";
    encryption.mode = "none";
    repo = "/hester/backups/teamspeak";
    startAt = "*-*-* 06:00:00";
  };
  systemd.services.borgbackup-job-teamspeak.unitConfig.RequiresMountsFor =
    "/hester";
}
