{ pkgs, specialArgs, ... }: {
    home.stateVersion = "21.05";

    programs.home-manager.enable = true;

    home.file.".face".source = ./face;
    home.file.".background-image".source = ./background-image;

    xdg.configFile."user-dirs.dirs".source =
      ./home/xdg-config/user-dirs.dirs;

    xdg.configFile."xfce4/terminal/terminalrc".source =
      ./home/xdg-config/xfce4/terminal/terminalrc;

    ########################################################################
    ## Doom Emacs

    nixpkgs.overlays = [
      ## This overlay is the `emacs-overlay`. It brings two new version of Emacs
      ## into the packages: `emacsUnstable` and `emacsGit`. The former is the
      ## last release on the git, while the latter is the last state of the git
      ## `master` branch.
      specialArgs.emacs-overlay

      ## This overlay replaces `emacs` by `emacsGit` (cf `emacs-overlay` above).
      ## We do that in order to have an Emacs 29+ on our system. FIXME: When
      ## `emacsUnstable` reaches 29+, replace by `emacsUnstable`. When `emacs`
      ## reaches 29+, get rid of both overlays.
      (self: super: {
        emacs = self.emacsGit;
      })
    ];

    home.packages = [
      ## The following brings the `doom-emacs` package on the system, which
      ## wraps `pkgs.emacs` into a Doom Emacs. There is no need for a
      ## `~/.emacs.d` directory, everything is handled in
      ## `/etc/nixos/home/doom.d`.
      (pkgs.callPackage specialArgs.nix-doom-emacs {
        doomPrivateDir = ./home/doom.d;
      })
    ];

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

        ## The `nrun` command tries to find the given command name for you,
        ## either by pulling it from the `PATH` (although you probably already
        ## tried that) or by pulling it from the `nixpkgs` flake.
        ##
        nrun () (
          cmd=$1; shift
          if command -v "$cmd" >/dev/null; then
            "$cmd" "$@"
          elif nix search nixpkgs "^$cmd\$" >/dev/null 2>&1; then
            nix run nixpkgs#"$cmd" -- "$@"
          else
            echo "Command '$cmd' could not be found in the system or in nixpkgs." >&2
            exit 127
          fi
        )
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
  }
