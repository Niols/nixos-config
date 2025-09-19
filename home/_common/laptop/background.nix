{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  setBackgroundCommand = ''
    ${pkgs.feh}/bin/feh --no-fehbg --bg-max ${config.x_niols.backgroundImageFile}
  '';

in

{
  options.x_niols.backgroundImageFile = mkOption {
    description = ''
      Path to the image to use as background.

      It is important that this path ends with an image extension.
      ## FIXME: check that in this option.
    '';
    type = types.path;
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
    programs.autorandr.hooks.postswitch.feh = setBackgroundCommand;
  };
}
