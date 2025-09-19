{ config, ... }:

{
  xfconf.settings = {
    xfce4-terminal = {
      background-mode = "TERMINAL_BACKGROUND_IMAGE";
      background-image-file = config.x_niols.backgroundImageFile;
      background-image-style = "TERMINAL_BACKGROUND_STYLE_CENTERED";
      background-darkness = 0.6;
      background-image-shading = 0.6;
    };
  };
}
