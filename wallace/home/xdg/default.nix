{ config }:

{
  userDirs = {
    enable = true;
    desktop = "${config.home.homeDirectory}";
    documents = "${config.home.homeDirectory}/NiolsCloud/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/NiolsCloud/Musique";
    pictures = "${config.home.homeDirectory}/NiolsCloud/Images";
    videos = "${config.home.homeDirectory}/NiolsCloud/Vidéos";

    publicShare = "${config.home.homeDirectory}";
    templates = "${config.home.homeDirectory}";

    createDirectories = false;
  };

  configFile."xfce4/terminal/terminalrc".source = ./xfce4-terminalrc;
}
