{ pkgs, ... }:

{
  imports = [ ../_common/laptop ];

  home.username = "work";
  home.homeDirectory = "/home/work";

  home.file.".face".source = ./face.jpg;

  home.packages = with pkgs; [
    slack
    zoom-us
  ];
}
