{
  services.postgresql.enable = true;

  services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 04:15:00";
    location = "/hester/backups/databases/orianne";
  };
  systemd.services.postgresqlBackup.unitConfig.RequiresMountsFor =
    "/hester/backups";
}
