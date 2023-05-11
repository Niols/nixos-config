_: {
  services.syncthing = {
    enable = true;
    user = "syncthing";
    dataDir = "/home/syncthing";
    configDir = "/home/syncthing/.config/syncthing";
    guiAddress = "0.0.0.0:8384"; ## FIXME: hide behind Nginx
    extraOptions.gui = {
      user = "niols";
      password = "syncthingpassword";
    };
  };
}
