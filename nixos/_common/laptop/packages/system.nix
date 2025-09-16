{ pkgs, ... }:
with pkgs;
[
  ## A
  arandr # REVIEW: probably not needed now that we have autorandr
  ardour
  asunder
  audacity

  ## C
  ## caffeine-ng -> the behaviour is really inconsistent

  ## E
  element-desktop
  evince

  ## F
  ffmpeg-full
  file-roller # REVIEW: what is this for?
  filezilla
  firefox

  ## G
  ghostscript # for `gs`, which `imagemagick` uses for PDF manipulation
  gimp
  gnucash
  gnupg
  guile # REVIEW: is it needed? maybe for LilyPond?
  guvcview # REVIEW: what is this for?

  ## I
  inkscape
  imagemagick

  ## K
  keepassxc

  ## L
  ledger-live-desktop # Wallet app for Ledger devices
  libreoffice
  lilypond

  ## M
  mosh

  ## N
  nautilus
  nautilus-open-any-terminal
  nextcloud-client

  ## P
  pdfgrep
  pdftk
  picard
  pkg-config # REVIEW: remove, move to `both`, or move to a new `dev` packages module

  ## S
  scrcpy # REVIEW: remove, move to `both`, or move to a new `dev` packages module
  signal-desktop
  steam-run

  ## T
  texlive.combined.scheme-full
  thunderbird
  tmate

  ## V
  vdhcoapp # companion for Video DownloadHelper
  vlc

  ## X
  xf86_input_wacom # wacom tablet support + `xsetwacom`
  xournalpp

  ## Y
  # youtube-dl ## unmaintained; switch to yt-dlp if possible.

  ## Z
  zoom
]
