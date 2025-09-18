{ config }:

{
  userDirs = {
    enable = true;
    desktop = "${config.home.homeDirectory}";
    documents = "${config.home.homeDirectory}/NiolsCloud/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Musique";
    pictures = "${config.home.homeDirectory}/NiolsCloud/Images";
    videos = "${config.home.homeDirectory}/Videos";

    publicShare = "${config.home.homeDirectory}";
    templates = "${config.home.homeDirectory}";

    createDirectories = false;
  };
}
