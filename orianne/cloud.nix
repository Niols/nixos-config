{ pkgs, ... }:

{
  services.nextcloud = {
    enable = true;

    package = pkgs.nextcloud26;

    hostName = "new.cloud.niols.fr";

    home = "/hester/services/nextcloud-test";

    https = true; # use HTTPS for links

    # autoUpdateApps.enable = true;

    config = {
      adminpassFile = "/etc/nextcloud-admin-pass";
      adminuser = "admin";
    };
  };

  environment.etc."nextcloud-admin-pass".text = "test123";
}
