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
	 "zoom"
      ]);

  environment.systemPackages = with pkgs; [
    ## A
    aspellDicts.fr
    aspellDicts.uk
    asunder
    audacity

    ## B
    bc
    bintools

    ## C
    calc
    chromium

    ## D
    dig
    discord

    ## E
    element-desktop
    emacs
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
    ispell

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

    ## P
    picard
    pkg-config
    python39Packages.py3status  ## python3.9-py3statyus

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
