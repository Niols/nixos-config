{ pkgs, ... }:

let hostName = "new.cloud.niols.fr";

in {
  services.nginx.virtualHosts.${hostName} = {
    forceSSL = true;
    enableACME = true;
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud26;

    inherit hostName;

    ## Home is on the machine, but the data directory is on Hester. We don't
    ## check permissions.
    home = "/var/lib/nextcloud-test";
    datadir = "/hester/services/nextcloud-test";
    # extraOptions.check_data_directory_permissions = false;
    # extraOptions.localstorage.umask = "0777";

    https = true; # use HTTPS for links

    # autoUpdateApps.enable = true;

    config = {
      adminuser = "admin";
      adminpassFile = "/etc/nextcloud-admin-pass-tmp";

      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      dbpassFile = "/etc/nextcloud-db-pass-tmp";
    };
  };

  users.groups.hester.members = [ "nextcloud" ];

  environment.etc."nextcloud-admin-pass-tmp".text = "test123";
  environment.etc."nextcloud-db-pass-tmp".text = "dbtest123";

  services.postgresql = {
    enable = true;

    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [{
      name = "nextcloud";
      ensureDBOwnership = true;
    }];
  };

  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
}
