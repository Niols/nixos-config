{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.syncthing = {
    enable = true;
    user = "niols";
    configDir = "/home/niols/.config/syncthing/";

    key = config.age.secrets."syncthing-${config.x_niols.thisMachinesName}-key".path;
    cert = config.age.secrets."syncthing-${config.x_niols.thisMachinesName}-cert".path;

    x_niols = {
      enableCommonFoldersAndDevices = true;
      thisDevice = lib.toSentenceCase config.x_niols.thisMachinesName; # FIXME: duplicate options
      defaultFolderPrefix = "~/.syncthing";
    };
  };

  environment.systemPackages = [ pkgs.syncthingtray ];
}
