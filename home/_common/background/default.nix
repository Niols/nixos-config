{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption mkIf types;

  setBackgroundCommand = ''
    ${pkgs.feh}/bin/feh --no-fehbg --bg-center ${config.x_niols.backgroundImageFile}
  '';

in

{
  options.x_niols.backgroundImageFile = mkOption {
    description = ''
      Path to the image to use as background.

      This must be a string so as to avoid the path being imported. Use string
      interpolation, eg. "''${./path/to/my/image.jpg}". The path MUST end with
      an image extension to ensure that all the services pick it up properly.
      ## FIXME: check that in this option.
    '';
    type = types.str;
    default = "${if config.x_niols.isWork then ./work.jpg else ./niols.jpg}";
  };

  config = mkIf (!config.x_niols.isHeadless) {
    ## Set background when (re)starting i3.
    xsession.windowManager.i3.config.startup = [
      {
        command = setBackgroundCommand;
        always = true;
        notification = false;
      }
    ];

    ## Also set background whenever autorandr changes the configuration.
    ## NOTE: Most of the `autorandr` configuration happens at the NixOS level,
    ## but this one thing depends per user.
    programs.autorandr = {
      enable = true;
      hooks.postswitch.set-background = setBackgroundCommand;
    };

    ## Disable the Xfce-specific equivalent of autorandr.
    xfconf.settings.displays = {
      Notify = 0;
      AutoEnableProfiles = 0;
    };
  };
}
