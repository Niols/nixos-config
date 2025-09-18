{ pkgs, ... }:

{
  imports = [
    ../_common/laptop.nix
    ./ocaml.nix
    ./ssh.nix
  ];

  home.username = "niols";
  home.homeDirectory = "/home/niols";

  home.file.".face".source = ./face.jpg;

  ## FIXME: This is an indeirection. Our feh script could take the store
  ## path directly.
  home.file.".background-image".source = ./background.jpg;

  ## It is important that the path ends in `.jpg`, without which xfce4-terminal
  ## will not pick it up.
  xfconf.settings.xfce4-terminal.background-image-file = "${./background.jpg}";

  ## FIXME: A common option that feeds into the background with feh and the
  ## terminal's background.

  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  ## Packages that are only ever used on my personal laptops. They should not
  ## clutter work's environment, (and that eliminates the temptation to have
  ## Signal or Thunderbird running)!
  home.packages = with pkgs; [
    audacity
    element-desktop
    gnucash
    inkscape
    ledger-live-desktop
    libreoffice
    lilypond
    picard
    signal-desktop
    thunderbird
    vlc
  ];
}
