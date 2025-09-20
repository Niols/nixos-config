{ ... }:

{
  imports = [
    ../_common
    ./ssh.nix
  ];

  x_niols.isHeadless = false;
  home.file.".face".source = ./face.jpg;
}
