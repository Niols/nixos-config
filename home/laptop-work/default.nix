{
  imports = [
    ../_common/laptop.nix
    ./packages.nix
    ./ssh.nix
  ];

  home.username = "work";
  home.homeDirectory = "/home/work";

  home.file.".face".source = ./face.jpg;

  x_niols.backgroundImageFile = "${./background.jpg}";
}
