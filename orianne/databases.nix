{
  services.postgresql.enable = true;

  ############################################################################
  ## Backup
  ##
  ## It is up to the other services to add their database to the list and save
  ## the corresponding file in the right place. They are encouraged to do their
  ## own backup some time after 04:00 and to include their file.

  services.postgresqlBackup = {
    enable = true;
    startAt = "*-*-* 04:00:00";
    backupAll = false;
  };
}
