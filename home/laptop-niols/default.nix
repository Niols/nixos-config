{ ... }:

{
  imports = [
    ../_common
    ./ssh.nix
  ];

  x_niols.isHeadless = false;
  home.file.".face".source = ./face.jpg;
  x_niols.backgroundImageFile = "${./background.jpg}";
}
