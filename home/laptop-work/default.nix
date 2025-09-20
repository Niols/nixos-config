{
  imports = [
    ../_common/laptop.nix
    ./packages.nix
    ./ssh.nix
  ];

  home.file.".face".source = ./face.jpg;
  x_niols.backgroundImageFile = "${./background.jpg}";
}
