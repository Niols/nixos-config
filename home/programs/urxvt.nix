{
  enable = true;

  ## List of fonts to be used.
  fonts = [
    "xft:DejaVu Sans Mono:style=Normal:antialias=true:size=10:minspace=False"
  ];

  ## Mapping of keybindings to actions.
  keybindings = {
    "Shift-Control-C" = "eval:selection_to_clipboard";
    "Shift-Control-V" = "eval:paste_clipboard";
    "Control-minus" = "resize-font:smaller";
    "Control-plus" = "resize-font:bigger";
    "Control-equal" = "resize-font:equal";
  };

  ## Whether to enable the scrollbar.
  scroll.bar.enable = false;

  ## Whether to enable pseudo-transparency.
  transparent = true;

  extraConfig = {
    ## special
    "foreground" = "#93a1a1";
    "background" = "#141c21";
    "cursorColor" = "#afbfbf";
    ## black
    "color0" = "#263640";
    "color8" = "#4a697d";
    ## red
    "color1" = "#d12f2c";
    "color9" = "#fa3935";
    ## green
    "color2" = "#819400";
    "color10" = "#a4bd00";
    ## yellow
    "color3" = "#b08500";
    "color11" = "#d9a400";
    ## blue
    "color4" = "#2587cc";
    "color12" = "#2ca2f5";
    ## magenta
    "color5" = "#696ebf";
    "color13" = "#8086e8";
    ## cyan
    "color6" = "#289c93";
    "color14" = "#33c5ba";
    ## white
    "color7" = "#bfbaac";
    "color15" = "#fdf6e3";
  };
}
