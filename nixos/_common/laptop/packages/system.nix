{ pkgs, ... }:
with pkgs;
[
  ## A
  arandr # REVIEW: probably not needed now that we have autorandr
  ardour
  asunder

  ## C
  ## caffeine-ng -> the behaviour is really inconsistent

  ## E
  evince

  ## F
  ffmpeg-full
  file-roller # REVIEW: what is this for?
  filezilla
  firefox

  ## G
  ghostscript # for `gs`, which `imagemagick` uses for PDF manipulation
  gimp
  guile # REVIEW: is it needed? maybe for LilyPond?
  guvcview # REVIEW: what is this for?

  ## I
  imagemagick

  ## N
  nautilus
  nautilus-open-any-terminal

  ## P
  pdfgrep
  pdftk
  pkg-config # REVIEW: remove, move to `both`, or move to a new `dev` packages module

  ## S
  scrcpy # REVIEW: remove, move to `both`, or move to a new `dev` packages module
  steam-run

  ## T
  texlive.combined.scheme-full
  tmate

  ## V
  vdhcoapp # companion for Video DownloadHelper

  ## X
  xf86_input_wacom # wacom tablet support + `xsetwacom`
  xournalpp

  ## Y
  # youtube-dl ## unmaintained; switch to yt-dlp if possible.
]
