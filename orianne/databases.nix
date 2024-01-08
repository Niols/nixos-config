{
  services.postgresql.enable = true;

  services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 19:00:00";
    location = "/hester/backups/databases/orianne";
  };
  systemd.services.postgresqlBackup.unitConfig.RequiresMountsFor = "/hester";
}
