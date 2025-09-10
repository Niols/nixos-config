{
  config,
  secrets,
  pkgs,
  ...
}:

{
  services.syncthing = {
    enable = true;
    user = "niols";
    configDir = "/home/niols/.config/syncthing/";

    key = config.age.secrets."syncthing-${config.x_niols.thisDevicesNameLower}-key".path;
    cert = config.age.secrets."syncthing-${config.x_niols.thisDevicesNameLower}-cert".path;

    x_niols = {
      enableCommonFoldersAndDevices = true;
      thisDevice = config.x_niols.thisDevicesName; # FIXME: duplicate options
      defaultFolderPrefix = "~/.syncthing";
    };

    ## FIXME: rename folder - or better, add Doom to Nix configuration.
    ## nix-doom-emacs used to exist, but was discontinued, I believe?
    settings.folders = {
      "Wallace/.config/doom".path = "~/.config/doom";
    };
  };

  environment.systemPackages = [ pkgs.syncthingtray ];
}
