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
    ## Tango colour palette
    "foreground" = "white";
    "background" = "black";
    "color0" = "#2E3436";
    "color1" = "#a40000";
    "color2" = "#4E9A06";
    "color3" = "#C4A000";
    "color4" = "#3465A4";
    "color5" = "#75507B";
    "color6" = "#ce5c00";
    "color7" = "#babdb9";
    "color8" = "#555753";
    "color9" = "#EF2929";
    "color10" = "#8AE234";
    "color11" = "#FCE94F";
    "color12" = "#729FCF";
    "color13" = "#AD7FA8";
    "color14" = "#fcaf3e";
    "color15" = "#EEEEEC";
  };
}
