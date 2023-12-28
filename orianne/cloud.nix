{ pkgs, ... }:

{
  services.nginx.virtualHosts.cloud = {
    serverName = "new.cloud.niols.fr";

    forceSSL = true;
    enableACME = true;
  };

  services.nextcloud = {
    # enable = true;

    package = pkgs.nextcloud26;

    hostName = "new.cloud.niols.fr";

    ## Home is on the machine, but the data directory is on Hester. We don't
    ## check permissions.
    home = "/var/lib/nextcloud-test";
    datadir = "/hester/services/nextcloud-test/data";
    extraOptions.check_data_directory_permissions = false;
    extraOptions.localstorage.umask = "0777";

    https = true; # use HTTPS for links

    # autoUpdateApps.enable = true;

    config = {
      adminuser = "admin";
      adminpassFile = "/etc/nextcloud-admin-pass-tmp";
    };
  };

  users.groups.hester.members = [ "nextcloud" ];

  environment.etc."nextcloud-admin-pass-tmp".text = "test123";
}
