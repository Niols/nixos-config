{
  imports = [ ./laptop ];

  home.username = "niols";
  home.homeDirectory = "/home/niols";

  home.file.".face".source = ./laptop-niols/face.jpg;
}
