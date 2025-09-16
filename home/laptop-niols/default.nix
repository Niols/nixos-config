{
  imports = [ ../_common/laptop ];

  home.username = "niols";
  home.homeDirectory = "/home/niols";

  home.file.".face".source = ./face.jpg;
}
