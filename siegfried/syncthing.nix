{ config, secrets, ... }:

{
  services.syncthing = {
    enable = true;
    user = "syncthing";
    dataDir = "/home/syncthing";
    configDir = "/home/syncthing/.config/syncthing";
    guiAddress = "127.0.0.1:8384";
  };

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
