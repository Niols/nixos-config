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
    gtk = {
      enable = true;

      theme.name = "Adwaita-dark";
      iconTheme.name = "Adwaita";
      # iconTheme.package = pkgs.adwaita-icon-theme;

      gtk2.extraConfig = ''
        gtk-key-theme-name = "Emacs"
      '';
      gtk3.extraConfig = {
        gtk-key-theme-name = "Emacs";
        gtk-application-prefer-dark-theme = true;
      };
      #gtk4.extraConfig = {
      #  # gtk-key-theme-name = "Emacs";
      #  gtk-application-prefer-dark-theme = true;
      #};
    };

    ## Fix "error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files"
    ## see https://github.com/nix-community/home-manager/issues/3113
    home.packages = [ pkgs.dconf ];
  };
}
