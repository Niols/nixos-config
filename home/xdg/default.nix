{ config }:

{
  userDirs = {
    enable = true;
    desktop = "${config.home.homeDirectory}";
    documents = "${config.home.homeDirectory}/NiolsCloud/Documents";
    music = "${config.home.homeDirectory}/NiolsCloud/Music";
    pictures = "${config.home.homeDirectory}/NiolsCloud/Images";
    videos = "${config.home.homeDirectory}/NiolsCloud/Vidéos";
  };

  configFile."xfce4/terminal/terminalrc".source =
    ./xfce4-terminalrc;
}
