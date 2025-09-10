# # FIXME: Normally, I would pass the `inputs` as an `extraSpecialArgs` both in
## NixOS and Home Manager configurations. However, doing this leads to infinite
## recursions, so I am just giving up for the moment.
{ inputs }:

{
  lib,
  pkgs,
  config,
  ...
}:

{
  imports = [
    ../_modules/niols-starship.nix
    programs/garbage-collect.nix
    programs/rebuild.nix
    inputs.nix-index-database.homeModules.nix-index
    ./packages.nix
    ./direnv.nix
    ./i3.nix
  ];

  home.stateVersion = "21.05";

  programs.home-manager.enable = true;

  home.file.".face".source = ../_assets/face.jpg;
  home.file.".background-image".source = ../_assets/background-image.jpg;

  xdg = import ./xdg { inherit config; };

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
