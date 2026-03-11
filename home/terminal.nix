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
    (mkIf config.x_niols.isGraphical {
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

    {
      programs.tmux = {
        enable = true;
        escapeTime = 0;
        historyLimit = 1000000;
        keyMode = "vi";
        mouse = true;

        ## Hide the status bar, but trigger hooks on window creation/deletion to
        ## show the status bar if there are more than 1 windows.
        extraConfig = ''
          set -g status off
          set-hook -g window-linked   'if -F "#{e|>:#{session_windows},1}" "set status on" "set status off"'
          set-hook -g window-unlinked 'if -F "#{e|>:#{session_windows},1}" "set status on" "set status off"'
        '';
      };
    }

    {
      programs.bash = {
        enable = true;

        bashrcExtra = ''
          ## Keep the prompt when entering `nix shell`.
          ##
          ## NOTE: We put this here instead of in
          ## `home.sessionVariables` because the latter only works for
          ## login Shells.
          ##
          ## cf https://discourse.nixos.org/t/*/8488/23
          ##
          NIX_SHELL_PRESERVE_PROMPT=yes
        '';

        initExtra = ''
          ## If there is a MOTD and we are not entering a Nix shell, then we print the
          ## MOTD in question.
          ##
          if [ -f /var/run/motd.dynamic ] && ! [ -n "$IN_NIX_SHELL" ]; then
            cat /var/run/motd.dynamic
          fi
        '';
      };

      programs.fzf.enable = true;
    }
  ];
}
