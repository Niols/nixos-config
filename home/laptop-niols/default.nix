{ pkgs, ... }:

{
  imports = [
    ../_common/laptop
    ./ocaml.nix
    ./ssh.nix
  ];

  home.username = "niols";
  home.homeDirectory = "/home/niols";

  home.file.".face".source = ./face.jpg;

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
    nextcloud-client
    vlc
  ];
}
