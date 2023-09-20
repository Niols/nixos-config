{ config, secrets, ... }:

{
  services.syncthing = {
    enable = true;
    user = "syncthing";

    key = config.age.secrets.syncthing-siegfried-key.path;
    cert = config.age.secrets.syncthing-siegfried-cert.path;

    guiAddress = "127.0.0.1:8384";
    settings.gui.insecureSkipHostcheck = true;

    overrideFolders = true;
    settings.folders = {
      Music = {
        path = "/hester/music";
        ignorePerms = true;
      };

      Organiser = {
        path = "/hester/organiser";
        ignorePerms = true;
      };
    };

    ## NOTE: `readFile` is usually very bad with secrets. However, here, we are
    ## only talking about the ids of the peers, so it is not the worst. Ideally,
    ## though, we could get the ids from a path.
    overrideDevices = true;
    devices = {
      "Barbara".id =
        builtins.readFile config.age.secrets.syncthing-barbara-id.path;
      "Philippe".id =
        builtins.readFile config.age.secrets.syncthing-philippe-id.path;
      "Wallace".id =
        builtins.readFile config.age.secrets.syncthing-wallace-id.path;
    };
  };

  users.groups.hester.members = [ "syncthing" ];

  systemd.services.syncthing-init.unitConfig.RequiresMountsFor = "/hester";
  systemd.services.syncthing.unitConfig.RequiresMountsFor = "/hester";

  services.nginx.virtualHosts.syncthing = {
    serverName = "syncthing.niols.fr";

    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8384";
      basicAuthFile = config.age.secrets.syncthing-siegfried-passwd.path;
    };
  };

  age.secrets.syncthing-siegfried-passwd = {
    file = "${secrets}/syncthing-siegfried-passwd.age";
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  age.secrets.syncthing-siegfried-key.file =
    "${secrets}/syncthing-siegfried-key.age";
  age.secrets.syncthing-siegfried-cert.file =
    "${secrets}/syncthing-siegfried-cert.age";
  age.secrets.syncthing-barbara-id.file = "${secrets}/syncthing-barbara-id.age";
  age.secrets.syncthing-philippe-id.file =
    "${secrets}/syncthing-philippe-id.age";
  age.secrets.syncthing-wallace-id.file = "${secrets}/syncthing-wallace-id.age";
}
