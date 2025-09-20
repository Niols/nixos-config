{ config, lib, ... }:

let
  inherit (lib) mkOption mkIf types;

in

{
  options.x_niols.terminalEmulatorCommand = mkOption {
    description = ''
      Command to run the terminal emulator. This option is meant to be used in
      other places in the configuration, so as to avoid hardcoding the terminal
      emulator.
    '';
    type = types.str;
    default = "xfce4-terminal";
  };

  config = mkIf (!config.x_niols.isHeadless) {
    xfconf.settings.xfce4-terminal = {
      background-mode = "TERMINAL_BACKGROUND_IMAGE";
      background-image-file = config.x_niols.backgroundImageFile;
      background-image-style = "TERMINAL_BACKGROUND_STYLE_CENTERED";
      background-darkness = 0.6;
      background-image-shading = 0.6;
    };
  };
}
