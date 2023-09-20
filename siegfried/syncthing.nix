{ config, secrets, ... }:

{
  services.syncthing = {
    enable = true;
    # user = "syncthing";
    # group = "public";
    dataDir = "/hester/services/syncthing";
    configDir = "/hester/services/syncthing/config";
    guiAddress = "127.0.0.1:8384";

    overrideFolders = true;
    settings.folders = {
      # Music.path = "/hester/music";
      Organiser.path = "/hester/organiser";
    };
  };

  # users.groups.hester.members = [ "syncthing" ];

  systemd.services.syncthing-init.unitConfig.RequiresMountsFor = "/hester";
  systemd.services.syncthing.unitConfig.RequiresMountsFor = "/hester";

  age.secrets.syncthing-passwd = {
    file = "${secrets}/syncthing-passwd.age";
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  services.nginx.virtualHosts.syncthing = {
    serverName = "syncthing.niols.fr";

    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8384";
      basicAuthFile = config.age.secrets.syncthing-passwd.path;
    };
  };
}
