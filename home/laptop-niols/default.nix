{ ... }:

{
  imports = [
    ../_common
    ./ssh.nix
  ];

  x_niols.isHeadless = false;
}
