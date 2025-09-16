{
  imports = [ ./laptop ];

  home.username = "work";
  home.homeDirectory = "/home/work";

  home.file.".face".source = ./laptop-work/face.jpg;
}
