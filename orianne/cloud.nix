{ config, secrets, pkgs, ... }:

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

    home = "/var/lib/nextcloud-test";
    datadir = "/hester/services/nextcloud-test";

    https = true; # use HTTPS for links

    # autoUpdateApps.enable = true;

    config = {
      adminuser = "admin";
      adminpassFile = config.age.secrets.nextcloud-admin-password.path;

      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
    };
  };

  users.groups.hester.members = [ "nextcloud" ];

  environment.etc."nextcloud-admin-pass-tmp".text = "test123";

  age.secrets.nextcloud-admin-password = {
    file = "${secrets}/nextcloud-admin-password.age";
  };

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
