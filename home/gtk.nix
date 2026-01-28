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
    ## NOTE: GTK theme configuration is a mess due to multiple detection methods:
    ##
    ## 1. GTK2/3 applications refer directly to GTK settings (gtk-theme-name,
    ##    gtk-application-prefer-dark-theme).
    ##
    ## 2. Modern GNOME/libadwaita applications rely on gsettings/dconf
    ##    (/org/gnome/desktop/interface/{gtk-theme,color-scheme})
    ##
    ## 3. Even more modern applications (Firefox, Nautilus) query the XDG
    ##    Desktop Portal (org.freedesktop.appearance::color-scheme), whose
    ##    backends translate from system settings (GTK/dconf/etc).
    ##    See `nixos/_common/laptop/xserver/default.nix`
    ##
    ## Home Manager provides a unified interface with `gtk.theme.name` and
    ## `gtk.colorScheme`, for instance, which should propage to all the right
    ## options everywhere.

    gtk = {
      enable = true;

      theme.package = pkgs.gnome-themes-extra;
      theme.name = "Adwaita-dark";
      colorScheme = "dark"; # will set `gtk-application-prefer-dark-theme` and dconf's `org/gnome/desktop/interface/color-scheme`
      iconTheme.name = "Adwaita";
      cursorTheme.name = "Adwaita";

      gtk2.extraConfig = ''
        gtk-key-theme-name = "Emacs"
      '';
      gtk3.extraConfig.gtk-key-theme-name = "Emacs";
      gtk4.extraConfig.gtk-key-theme-name = "Emacs";
    };

    ## Fix "error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files"
    ## see https://github.com/nix-community/home-manager/issues/3113
    home.packages = [ pkgs.dconf ];
  };
}
