{ lib, pkgs, config, inputs, ... }:

{
  imports = [
    ../_modules/niols-starship.nix
    programs/garbage-collect.nix
    inputs.nix-index-database.hmModules.nix-index
  ];

  home.stateVersion = "21.05";

  programs.home-manager.enable = true;

  home.file.".face".source = ../_assets/face;
  home.file.".background-image".source = ../_assets/background-image;

  xdg = import ./xdg { inherit config; };

  home.packages = with pkgs; [
    ## Necessary for i3; I much prefer running it standalone.
    rofimoji

    ## Fix "error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files"
    ## see https://github.com/nix-community/home-manager/issues/3113
    dconf

    ripgrep # provides `rg`
    fd # alternative to `find` needed by Doom Emacs

    emacs
    cmake # necessary for Emacs's `vterm`
    libtool # necessary for Emacs's `vterm`
    nodejs # necessary for Emacs's `copilot`
    python3 # needed by TreeMacs
  ];

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
