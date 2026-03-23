{
  lib,
  osConfig,
  config,
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
    ./monorepo.nix
    ./nix.nix
    ./packages
    ./rclone.nix
    ./ssh.nix
    ./terminal.nix
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
    isPerso = mkOption {
      description = "Negation of isWork, for readability.";
      type = types.bool;
      default = !config.x_niols.isWork;
      readOnly = true;
    };

    isHeadless = mkOption {
      description = ''
        Whether this home environment is headless.
      '';
      type = types.bool;
      default = false;
    };
    isGraphical = mkOption {
      description = "Negation of isHeadless, for readability.";
      type = lib.types.bool;
      default = !config.x_niols.isHeadless;
      readOnly = true;
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

      ## NOTE: I don't actually use or care about Swaylock, but from March 2026
      ## onwards, leaving `enable` unspecified yields an evaluation warning.
      programs.swaylock.enable = false;
    }
  ];
}
