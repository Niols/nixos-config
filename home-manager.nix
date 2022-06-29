{ config, pkgs, ... }:

{
  home-manager.users.niols = { pkgs, ... }: {
    programs.home-manager.enable = true;

    xdg.configFile."user-dirs.dirs".text = ''
XDG_DESKTOP_DIR="$HOME"
XDG_DOCUMENTS_DIR="$HOME/NiolsCloud/Documents"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_MUSIC_DIR="$HOME/NiolsCloud/Musique"
XDG_PICTURES_DIR="$HOME/NiolsCloud/Images"
XDG_VIDEOS_DIR="$HOME/NiolsCloud/Vidéos"
    '';

    xdg.configFile."xfce4/terminal/terminalrc".text = ''
[Configuration]
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBellUrgent=FALSE
MiscBordersDefault=FALSE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=80x24
MiscInheritGeometry=FALSE
MiscMenubarDefault=FALSE
MiscMouseAutohide=FALSE
MiscMouseWheelZoom=TRUE
MiscToolbarDefault=FALSE
MiscConfirmClose=FALSE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscMiddleClickOpensUri=FALSE
MiscCopyOnSelect=FALSE
MiscShowRelaunchDialog=TRUE
MiscRewrapOnResize=TRUE
MiscUseShiftArrowsToScroll=FALSE
MiscSlimTabs=FALSE
MiscNewTabAdjacent=FALSE
MiscSearchDialogOpacity=100
MiscShowUnsafePasteDialog=FALSE
ScrollingBar=TERMINAL_SCROLLBAR_NONE
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
MiscRightClickAction=TERMINAL_RIGHT_CLICK_ACTION_CONTEXT_MENU
BackgroundDarkness=0.000000
    '';

    home.file.".bash_prompt".source = ./bash-prompt.sh;

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

    programs.firefox = {
      enable = true;
    };

    ########################################################################
    ## Bash

    programs.bash = {
      enable = true;
      bashrcExtra = ''
        if command -v opam >/dev/null; then eval $(opam env); fi
        alias cal='cal --monday'
        alias ls='ls --quoting-style=literal --color=auto'
	. ~/.bash_prompt
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
