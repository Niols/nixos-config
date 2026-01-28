{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;

in
{
  config = mkIf (!config.x_niols.isHeadless) {
    ## GTK themes are very messy. We use the simple Adwaita in dark mode, but
    ## different applications grab this setting from different places:
    ##
    ## - the `gtk.theme.name` setting
    ## - the `gtk-application-prefer-dark-theme` setting
    ## - GNOME configuration: `dconf read /org/gnome/desktop/interface/color-scheme`
    ## - the XDG Desktop Portal — see nixos/_common/laptop/xserver/default.nix

    gtk = {
      enable = true;

      theme.package = pkgs.gnome-themes-extra;
      theme.name = "Adwaita-dark";
      iconTheme.name = "Adwaita";
      cursorTheme.name = "Adwaita";

      gtk2.extraConfig = ''
        gtk-key-theme-name = "Emacs"
      '';

      gtk3.extraConfig = {
        gtk-key-theme-name = "Emacs";
        gtk-application-prefer-dark-theme = true;
      };

      ## NOTE: gtk-application-prefer-dark-theme is not supported by libadwaita
      ## applications. They grab the color scheme from dconf/xfconf instead.
    };

    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    ## Fix "error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files"
    ## see https://github.com/nix-community/home-manager/issues/3113
    home.packages = [ pkgs.dconf ];
  };
}
