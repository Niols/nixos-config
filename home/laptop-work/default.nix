{
  imports = [
    ../_common/laptop.nix
    ./packages.nix
    ./ssh.nix
  ];

  home.username = "work";
  home.homeDirectory = "/home/work";

  home.file.".face".source = ./face.jpg;

  ## FIXME: This is an indirection. Our feh script could take the store
  ## path directly.
  home.file.".background-image".source = ./background.jpg;

  ## It is important that the path ends in `.jpg`, without which xfce4-terminal
  ## will not pick it up.
  xfconf.settings.xfce4-terminal.background-image-file = "${./background.jpg}";

  ## FIXME: A common option that feeds into the background with feh and the
  ## terminal's background.
}
