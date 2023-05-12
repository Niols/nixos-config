_: {
  services.syncthing = {
    enable = true;
    user = "syncthing";
    dataDir = "/home/syncthing";
    configDir = "/home/syncthing/.config/syncthing";
    guiAddress = "127.0.0.1:8384";
    extraOptions.gui = {
      user = "niols";
      password = "syncthingpassword";
    };
  };

  services.nginx.virtualHosts.syncthing = {
    locations."/" = { proxyPass = "http://127.0.0.1:8384"; };
  };
}
