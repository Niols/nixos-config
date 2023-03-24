{
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
}
