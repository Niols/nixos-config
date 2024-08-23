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
  cmake # # necessary for Emacs's `vterm`
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
  file-roller
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
  libtool # # necessary for Emacs's `vterm`
  lilypond

  ## M
  mattermost-desktop
  mosh

  ## N
  nautilus
  nextcloud-client
  nix-output-monitor
  nodejs # # necessary for Emacs's `copilot`

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
