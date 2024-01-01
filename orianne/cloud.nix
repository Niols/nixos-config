{ config, secrets, pkgs, ... }:

let
  hostName = "cloud.niols.fr";

  ## FIXME: remove new.cloud.niols.fr once the transition is complete.
  otherHostNames = [ "new.cloud.niols.fr" "cloud.jeannerod.fr" ];

in {
  services.nextcloud = {
    enable = true;

    ## #####  Upgrading Nextcloud's version  ###################################
    ##
    ## From https://nixos.wiki/wiki/Nextcloud#Maintenance
    ##
    ## There is no default `nextcloud` package. Instead you have to set the
    ## current version in `services.nextcloud.package`. As soon a major version
    ## of Nextcloud gets unsupported, it will be removed from nixpkgs as well.
    ##
    ## Upgrading then consists of these steps:
    ##
    ## - Increment the version of services.nextcloud.package in your config by 1
    ##   (leaving out a major version is not supported)
    ##
    ## - `nixos-rebuild switch`
    ##
    ## In theory, your Nextcloud has now been upgraded by one version. NixOS
    ## attempts `nextcloud-occ upgrade`, if this succeeds without problems you
    ## don't need to do anything. Check `journalctl` to make sure nothing
    ## horrible happened. Go to the `/settings/admin/overview` page in your
    ## Nextcloud to see whether it recommends further processing, such as
    ## database reindexing or conversion.
    ##
    package = pkgs.nextcloud28;

    inherit hostName;
    config.extraTrustedDomains = otherHostNames;

    home = "/var/lib/nextcloud";
    datadir = "/var/lib/nextcloud";

    https = true; # use HTTPS for links

    ## Specify important apps via Nix. One can still install apps via the web
    ## interface. The latter get updated automatically.
    extraAppsEnable = true;
    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit calendar contacts impersonate previewgenerator tasks;
      ## FIXME: news keeweb onlyoffice cookbook
    };
    appstoreEnable = true;
    autoUpdateApps.enable = true;

    ## Necessary for CIFS external storage.
    phpExtraExtensions = p: [ p.smbclient ];

    configureRedis = true;

    secretFile = config.age.secrets.niolscloud-secrets.path;

    config = {
      adminuser = "admin";
      adminpassFile = config.age.secrets.niolscloud-admin-password.path;

      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";

      defaultPhoneRegion = "FR";
    };

    ## The `file` log type allows reading logs from the NextCloud interface.
    logType = "file";
  };

  age.secrets.niolscloud-admin-password = {
    file = "${secrets}/niolscloud-admin-password.age";
    mode = "640";
    owner = "nextcloud";
    group = "nextcloud";
  };

  age.secrets.niolscloud-secrets = {
    file = "${secrets}/niolscloud-secrets.age";
    mode = "640";
    owner = "nextcloud";
    group = "nextcloud";
  };

  services.postgresql = {
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [{
      name = "nextcloud";
      ensureDBOwnership = true;
    }];
  };

  ## Make sure Nextcloud only starts once the database is up.
  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  services.nginx.virtualHosts.${hostName} = {
    forceSSL = true;
    enableACME = true;
    serverAliases = otherHostNames;
  };
}
