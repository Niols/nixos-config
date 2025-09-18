{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

{
  imports = [
    ../../../_modules/niols-starship.nix
    programs/garbage-collect.nix
    programs/rebuild.nix
    inputs.nix-index-database.homeModules.nix-index
    ./packages.nix
    ./direnv.nix
    ./i3.nix
    ./ssh.nix
    ./xfce.nix
  ];

  programs.home-manager.enable = true;

  xdg = import ./xdg.nix { inherit config; };

  gtk = import ./gtk.nix;

  programs.fzf.enable = true;
  programs.bash = import ./programs/bash;
  programs.git = import ./programs/git.nix { inherit lib; };
  programs.lsd.enable = true;
  programs.urxvt = import ./programs/urxvt.nix;

  programs.rofi = {
    enable = true;
    plugins = [ pkgs.rofi-calc ];
  };

  # programs.starship = import ./programs/starship.nix;
  niols-starship = {
    enable = true;
    hostcolour = "green";
  };

  programs.nix-index.enable = true;
  programs.nix-index.symlinkToCacheHome = true;

  ############################################################################
  ## Tmux

  programs.tmux = {
    enable = true;
    escapeTime = 0;
    historyLimit = 1000000;
    keyMode = "vi";
    mouse = true;
  };
}
