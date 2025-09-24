{
  lib,
  config,
  inputs,
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
    ../_modules/niols-starship.nix
    programs/garbage-collect.nix
    inputs.nix-index-database.homeModules.nix-index
    ./packages.nix
    ./direnv.nix
    ./i3.nix
    ./ssh.nix
    ./terminal-emulator.nix
    ./background
    ./doom
    ./gtk.nix
    ./face
    ./git.nix
    ./keepassxc.nix
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

    isStandalone = mkOption {
      description = ''
        Whether this home environment is set up in a standalone way, that is not
        as part as a NixOS configuration.
      '';
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

      targets.genericLinux.enable = config.x_niols.isStandalone;
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
        '';
      };

      # programs.starship = import ./programs/starship.nix;
      niols-starship = {
        enable = true;
        hostcolour = "green";
      };

      programs.nix-index.enable = true;
      programs.nix-index.symlinkToCacheHome = true;

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
