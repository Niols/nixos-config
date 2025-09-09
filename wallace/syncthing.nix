{ config, secrets, ... }:

{
  services.syncthing = {
    enable = true;
    user = "niols";
    configDir = "/home/niols/.config/syncthing/";

    key = config.age.secrets.syncthing-wallace-key.path;
    cert = config.age.secrets.syncthing-wallace-cert.path;

    x_niols = {
      enableCommonFoldersAndDevices = true;
      thisDevice = "Wallace";
      defaultFolderPrefix = "~/.syncthing";
    };

    settings.folders = {
      "Wallace/.config/doom".path = "~/.config/doom";
    };
  };
}
