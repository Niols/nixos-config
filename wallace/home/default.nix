{ lib, pkgs, config, specialArgs, ... }: {
    home.stateVersion = "21.05";

    programs.home-manager.enable = true;

    home.file.".face".source = ../face;
    home.file.".background-image".source = ../background-image;

    xdg = import ./xdg { inherit config; };

    ########################################################################
    ## Doom Emacs

    home.packages = [
      ## The following brings the `doom-emacs` package on the system, which
      ## wraps `pkgs.emacs` into a Doom Emacs. There is no need for a
      ## `~/.emacs.d` directory, everything is handled in
      ## `/etc/nixos/home/doom.d`.
      (pkgs.callPackage specialArgs.nix-doom-emacs {
        doomPrivateDir = ./doom.d;
      })
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
    programs.starship = import ./programs/starship.nix;
}
