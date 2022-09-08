{ config, pkgs, ... }:

{
  home-manager.users.niols = { pkgs, ... }: {
    programs.home-manager.enable = true;

    home.file.".face".source = ./face;
    home.file.".background-image".source = ./background-image;

    xdg.configFile."user-dirs.dirs".source =
      ./home/xdg-config/user-dirs.dirs;

    xdg.configFile."xfce4/terminal/terminalrc".source =
      ./home/xdg-config/xfce4/terminal/terminalrc;

    ########################################################################
    ## GTK

    gtk = {
      enable = true;

      theme.name = "Adwaita-dark";
      iconTheme.name = "Adwaita";
      # iconTheme.package = pkgs.adwaita-icon-theme;

      gtk2.extraConfig = ''
        gtk-key-theme-name = "Emacs"
      '';
      gtk3.extraConfig = {
        gtk-key-theme-name = "Emacs";
        gtk-application-prefer-dark-theme = true;
      };
      #gtk4.extraConfig = {
      #  # gtk-key-theme-name = "Emacs";
      #  gtk-application-prefer-dark-theme = true;
      #};
    };

    ########################################################################
    ## Firefox

    programs.firefox.enable = true;

    ########################################################################
    ## Bash

    programs.bash = {
      enable = true;

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
    };

    ########################################################################
    ## Git

    programs.git = {
      enable = true;
      ignores = [ "*~" "*#" ];

      ## Require to sign by default, but give a useless key, forcing
      ## myself to setup the key correctly in the future.
      signing.key = "YOU NEED TO EXPLICITLY SETUP THE KEY";
      signing.signByDefault = true;

      ## Change of personality depending on the location in the file
      ## tree. This only switches between personal and profesionnal.
      includes = [
        {
          condition = "gitdir:~/git/perso/**";
          contents.user = {
            name = "Niols";
            email = "niols@niols.fr";
            signingKey = "2EFDA2F3E796FF05ECBB3D110B4EB01A5527EA54";
          };
        }
        {
          condition = "gitdir:~/git/boloss/**";
          contents.user = {
            name = "Niols";
            email = "niols@niols.fr";
            signingKey = "2EFDA2F3E796FF05ECBB3D110B4EB01A5527EA54";
          };
        }
        {
          condition = "gitdir:~/git/tweag/**";
          contents.user = {
            name = "Nicolas “Niols” Jeannerod";
            email = "nicolas.jeannerod@tweag.io";
            signingKey = "71CBB1B508F0E85DE8E5B5E735DB9EC8886E1CB8";
          };
        }
        {
          condition = "gitdir:~/git/hachi/**";
          contents.user = {
            name = "Nicolas “Niols” Jeannerod";
            email = "nicolas.jeannerod@tweag.io";
            signingKey = "71CBB1B508F0E85DE8E5B5E735DB9EC8886E1CB8";
          };
        }
      ];

      extraConfig.init.defaultBranch = "main";

      ## Rewrite GitHub's https:// URI to ssh://
      extraConfig.url = {
        "ssh://git@github.com" = { insteadOf = "https://github.com"; };
      };

      ## Enable git LFS
      lfs.enable = true;

      ## Lesser Known Git Commands, by Tim Pettersen
      ## https://dzone.com/articles/lesser-known-git-commands
      aliases = {
        it = "!git init && git commit -m “root” --allow-empty";
        commend = "commit --amend --no-edit";
        grog = "log --graph --abbrev-commit --decorate --all --format=format:\"%C(bold blue)\
%h%C(reset) - %C(bold cyan)%aD%C(dim white) - %an%C(reset) %C(bold green)(%ar)%C(reset)%C(bold\
 yellow)%d%C(reset)%n %C(white)%s%C(reset)\"";
      };
    };
  };
}
