{ config, pkgs, ... }:

{
  ## Packages installed in system profile. Allow a selected set of
  ## unfree packages for this list.
  nixpkgs.config.allowUnfreePredicate = (pkg: builtins.elem
      (pkgs.lib.getName pkg) [
          "discord"
          "skypeforlinux"
          "slack"
          "steam-original"
          "steam-runtime"
          "unrar"
          "zoom"
      ]);

  environment.systemPackages = with pkgs; [
    ## A
    arandr
    ardour
    (aspellWithDicts (dicts: [ dicts.fr dicts.uk ]))
    asunder
    audacity

    ## B
    bc
    bintools

    ## C
    ## caffeine-ng -> the behaviour is really inconsistent
    calc
    chromium

    ## D
    dig
    direnv
    discord

    ## E
    element-desktop
    ## emacs --> cf `home-manager.nix`
    evince

    ## F
    fd  ## alternative to 'find' needed by Doom Emacs
    ffmpeg-full
    gnome.file-roller
    filezilla
    firefox

    ## G
    gcc
    gimp
    git
    git-lfs
    gnumake
    gnupg
    guile
    guvcview

    ## H
    htop
    httpie

    ## I
    inkscape

    ## J
    jq

    ## K
    keepassxc

    ## L
    ledger-live-desktop ## Wallet app for Ledger devices
    libreoffice
    lilypond

    ## M
    mattermost-desktop
    mosh

    ## N
    gnome.nautilus
    nextcloud-client

    ## O
    opam

    ## P
    picard
    pkg-config

    ## R
    racket
    ripgrep

    ## S
    signal-desktop
    skypeforlinux
    slack
    steam-run

    ## T
    texlive.combined.scheme-full
    thunderbird

    ## U
    unrar
    unzip

    ## V
    vlc

    ## W
    wget

    ## X
    xf86_input_wacom  ## wacom tablet support + `xsetwacom`
    xorg.xev
    xournalpp

    ## Y
    yamllint
    youtube-dl

    ## Z
    zoom-us
  ];
}
