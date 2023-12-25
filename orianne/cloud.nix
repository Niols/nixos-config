{ pkgs, ... }:

{
  services.nextcloud = {
    enable = true;

    package = pkgs.nextcloud26;

    hostName = "new.cloud.niols.fr";

    home = "/var/lib/nextcloud-test";
    ## `datadir` is `home` by default

    https = true; # use HTTPS for links

    # autoUpdateApps.enable = true;

    config = {
      adminpassFile = "/etc/nextcloud-admin-pass";
      adminuser = "admin";
    };
  };

  users.groups.hester.members = [ "nextcloud" ];

  environment.etc."nextcloud-admin-pass".text = "test123";
}
