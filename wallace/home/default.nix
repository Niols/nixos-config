{ lib, pkgs, config, ... }: {
  imports = [ ../../_modules/niols-starship.nix programs/garbage-collect.nix ];

  home.stateVersion = "21.05";

  programs.home-manager.enable = true;

  home.file.".face".source = ../face;
  home.file.".background-image".source = ../background-image;

  xdg = import ./xdg { inherit config; };

  ########################################################################
  ## Doom Emacs

  home.packages = [
    ## Necessary for i3; I much prefer running it standalone.
    pkgs.rofimoji
  ];

  gtk = import ./gtk.nix;

  programs.fzf.enable = true;
  programs.bash = import ./programs/bash;
  programs.firefox = import ./programs/firefox.nix;
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
}
