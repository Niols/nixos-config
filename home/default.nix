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
  ];
}
