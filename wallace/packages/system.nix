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
  borgbackup

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
  entr
  evince

  ## F
  fd
  ffmpeg-full
  file-roller
  filezilla
  firefox

  ## G
  gcc
  gimp
  git
  git-lfs
  gnucash
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
  nautilus
  nextcloud-client
  nix-output-monitor

  ## P
  pdfgrep
  pdftk
  picard
  pkg-config

  ## R
  ripgrep

  ## S
  signal-desktop
  skypeforlinux
  slack
  # spotdl # broken as of 2023-11-10
  steam-run
  syncthingtray

  ## T
  texlive.combined.scheme-full
  thunderbird
  tmate

  ## U
  unrar
  unzip

  ## V
  vdhcoapp # companion for Video DownloadHelper
  vlc

  ## W
  wget

  ## X
  xf86_input_wacom # # wacom tablet support + `xsetwacom`
  xorg.xev
  xournalpp

  ## Y
  yamllint
  # youtube-dl ## unmaintained; switch to yt-dlp if possible.

  ## Z
  zoom-us
]
