{
  config,
  lib,
  pkgs,
  machines,
  ...
}:

let
  inherit (lib)
    mkIf
    mkForce
    ;

  postgresPort = 5432; # the default

in
{
  config = mkIf config.x_niols.isServer {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
    };

    services.postgresql = {
      enable = true;

      ## Allow TCP connections (in addition to Unix sockets) on loopback and on
      ## the internal network.
      enableTCPIP = true;
      settings = {
        port = postgresPort;
        listen_addresses = mkForce "127.0.0.1,${machines.this.internalIp}";
      };
      authentication = ''
        host all all ${machines.this.internalIp}/24 scram-sha-256
      '';
    };
    networking.firewall.allowedTCPPorts = [ postgresPort ];

    ############################################################################
    ## Backup
    ##
    ## It is up to the other services to add their database to the list and save
    ## the corresponding file in the right place. They are encouraged to do their
    ## own backup some time after 04:00 and to include their file.
    ##
    ## FIXME: for safety, we should just backup /var/backup/mysql and
    ## /var/backup/postgres ourselves anyway; otherwise if another service has a
    ## typo or something... that would be a shame.

    services.mysqlBackup = {
      enable = true;
      calendar = "03:45:00";
    };

    services.postgresqlBackup = {
      enable = true;
      startAt = "*-*-* 04:00:00";
      backupAll = false;
    };
  };
}
