{
  imports = [
    ../_common
    ./packages.nix
    ./ssh.nix
  ];

  x_niols.isWork = true;
  x_niols.isHeadless = false;
  home.file.".face".source = ./face.jpg;
}
