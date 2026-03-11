{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    mkIf
    mkMerge
    types
    ;

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

  config = mkMerge [
    (mkIf (!config.x_niols.isHeadless) {
      xfconf.settings.xfce4-terminal = {
        background-mode = "TERMINAL_BACKGROUND_IMAGE";
        background-image-file = config.x_niols.backgroundImageFile;
        background-image-style = "TERMINAL_BACKGROUND_STYLE_CENTERED";
        background-darkness = 0.6;
        background-image-shading = 0.6;
      };
    })

    {
      ## Enable true color/24-bit color support. This makes tools like Emacs,
      ## Vim, or Claude pretty in the terminal. NOTE: It is tempting to set
      ## `TERM=xterm-direct` as well, but this breaks things down, in particular
      ## with Mosh. Better let SSH or Mosh transmit the `TERM` variable that
      ## works for them.
      home.sessionVariables.COLORTERM = "truecolor";
    }
  ];
}
