{
  lib,
  osConfig,
  ...
}:

let
  inherit (builtins) getEnv;
  inherit (lib)
    mkDefault
    mkOption
    mkMerge
    types
    ;

in

{
  imports = [
    ../common

    ./background
    ./direnv.nix
    ./doom
    ./face
    ./git.nix
    ./gtk.nix
    ./i3.nix
    ./keepassxc.nix
    ./nix.nix
    ./packages
    ./ssh.nix
    ./terminal-emulator.nix
    ./xdg.nix
  ];

  options.x_niols = {
    isWork = mkOption {
      description = ''
        Whether this home environment is for work.
      '';
      type = types.bool;
      default = false;
    };

    isHeadless = mkOption {
      description = ''
        Whether this home environment is headless.
      '';
      type = types.bool;
      default = false;
    };
  };

  config = mkMerge [
    {
      home.stateVersion = "21.05";

      ## NOTE: It is important to enable Bash so that Home Manager activates
      ## properly. Otherwise, see Home Manager's documentation.
      programs.home-manager.enable = true;
      programs.bash.enable = true;

      home.username = mkDefault (getEnv "USER");
      home.homeDirectory = mkDefault (getEnv "HOME");

      ## Tweaks to make Home Manager work better on standalone installations.
      targets.genericLinux.enable = (osConfig == null);
    }

    ############################################################################
    ## TODO: Move this away.

    {
      programs.fzf.enable = true;

      programs.bash = {
        # enable = true;
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

          ## Pick up on gcr-ssh-agent if it is running. It is started on login
          ## by the NixOS configuration. See `nixos/_common/laptop/default.nix` (as
          ## of 28 Nov 2025).
          ##
          ## https://joshtronic.com/2024/03/10/gnome-keyring-disables-ssh-agent/
          ##
          if [ -e $XDG_RUNTIME_DIR/gcr/ssh ] && [ -z "''${SSH_AUTH_SOCK+x}" ]; then
            export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh
          fi
        '';
      };

      programs.tmux = {
        enable = true;
        escapeTime = 0;
        historyLimit = 1000000;
        keyMode = "vi";
        mouse = true;
      };
    }
  ];
}
