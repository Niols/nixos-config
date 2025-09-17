{
  imports = [
    ../_common/laptop
    ./packages.nix
    ./ssh.nix
  ];

  home.username = "work";
  home.homeDirectory = "/home/work";

  home.file.".face".source = ./face.jpg;
}
