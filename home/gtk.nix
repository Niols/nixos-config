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
    ## somehow different applications will grab this setting from different
    ## places; hence the many occurrences of Adwaita dark in this page.

    home.sessionVariables.GTK_THEME = "Adwaita:dark";

    gtk = {
      enable = true;

      theme.package = pkgs.gnome-themes-extra;
      theme.name = "Adwaita-dark";
      iconTheme.name = "Adwaita";
      cursorTheme.name = "Adwaita";
      # iconTheme.package = pkgs.adwaita-icon-theme;

      gtk2.extraConfig = ''
        gtk-key-theme-name = "Emacs"
      '';
      gtk3.extraConfig = {
        gtk-key-theme-name = "Emacs";
        gtk-application-prefer-dark-theme = true;
      };
      gtk4.extraConfig = {
        # gtk-key-theme-name = "Emacs";
        gtk-application-prefer-dark-theme = true;
      };
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Adwaita-dark";
      };
    };

    # xdg.configFile = {
    #   "gtk-4.0/assets".source =
    #     "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    #   "gtk-4.0/gtk.css".source =
    #     "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    #   "gtk-4.0/gtk-dark.css".source =
    #     "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
    # };

    ## Fix "error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files"
    ## see https://github.com/nix-community/home-manager/issues/3113
    home.packages = [ pkgs.dconf ];
  };
}
