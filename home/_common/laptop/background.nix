{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

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
  };

  config = {
    ## Background handling, when restarting i3, but also when switching outputs
    ## with `autorandr`.
    xsession.windowManager.i3.config.startup = [
      {
        command = setBackgroundCommand;
        always = true;
        notification = false;
      }
    ];

    ## NOTE: Most of the `autorandr` configuration happens at the NixOS level,
    ## except for this one thing.
    programs.autorandr = {
      enable = true;
      hooks.postswitch.set-background = setBackgroundCommand;
    };
  };
}
