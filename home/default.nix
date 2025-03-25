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
    inputs.nix-index-database.hmModules.nix-index
    ./packages.nix
    ./direnv.nix
  ];

  home.stateVersion = "21.05";

  programs.home-manager.enable = true;

  home.file.".face".source = ../_assets/face;
  home.file.".background-image".source = ../_assets/background-image;

  xdg = import ./xdg { inherit config; };

  gtk = import ./gtk.nix;

  programs.fzf.enable = true;
  programs.bash = import ./programs/bash;
  programs.git = import ./programs/git.nix { inherit lib; };
  programs.lsd = {
    enable = true;
    enableAliases = true;
  };
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

  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
  };

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
