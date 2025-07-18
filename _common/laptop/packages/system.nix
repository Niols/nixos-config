{ pkgs, ... }:
with pkgs;
[
  ## A
  arandr
  ardour
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
  ghostscript # for `gs`, which `imagemagick` uses for PDF manipulation
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
  jless
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
  nautilus-open-any-terminal
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
  scrcpy
  signal-desktop
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
