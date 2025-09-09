{ config, secrets, ... }:

{
  services.syncthing = {
    enable = true;
    user = "niols";
    configDir = "/home/niols/.config/syncthing/";

    key = config.age.secrets.syncthing-gromit-key.path;
    cert = config.age.secrets.syncthing-gromit-cert.path;

    x_niols = {
      enableCommonFoldersAndDevices = true;
      thisDevice = "Gromit";
      defaultFolderPrefix = "~/.syncthing";
    };

    settings.folders = {
      "Wallace/.config/doom".path = "~/.config/doom";
    };
  };
}
