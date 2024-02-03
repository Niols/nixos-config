{ pkgs, ... }:
with pkgs; [
  ## A
  arandr
  ardour
  (aspellWithDicts (dicts: [ dicts.fr dicts.uk ]))
  asunder
  audacity

  ## B
  bat
  bc
  bintools
  btop

  ## C
  ## caffeine-ng -> the behaviour is really inconsistent
  calc
  chromium
  comma

  ## D
  dig
  direnv
  nix-direnv
  discord

  ## E
  element-desktop
  emacs
  entr
  evince

  ## F
  fd # # alternative to 'find' needed by Doom Emacs
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
  imagemagick

  ## J
  jq

  ## K
  keepassxc
  killall

  ## L
  ledger-live-desktop # # Wallet app for Ledger devices
  libqalculate # # provides `qalc`
  libreoffice
  lilypond

  ## M
  mattermost-desktop
  mosh

  ## N
  gnome.nautilus
  nextcloud-client
  nix-output-monitor

  ## P
  pdfgrep
  pdftk
  picard
  pkg-config
  python3 # # needed by TreeMacs

  ## R
  ripgrep

  ## S
  signal-desktop
  skypeforlinux
  slack
  # spotdl # broken as of 2023-11-10
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
  xf86_input_wacom # # wacom tablet support + `xsetwacom`
  xorg.xev
  xournalpp

  ## Y
  yamllint
  youtube-dl

  ## Z
  zoom-us
]
