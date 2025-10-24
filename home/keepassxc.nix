{
  programs.keepassxc = {
    enable = true;
    autostart = true;
    settings = {
      Browser.Enabled = true;
      FdoSecrets.Enabled = false; # freedesktop.org secrets service, eg. for NextCloud
      GUI = {
        AdvancedSettings = true;
        ApplicationTheme = "dark";
        CompactMode = true;
        HidePasswords = true;
        MinimizeOnClose = true;
        MinimizeOnStartup = true;
        ShowTrayIcon = true;
        TrayIconAppearance = "colorful";
      };
    };
  };

  ## Necessary for `programs.keepassxc.autostart` to be effective.
  xdg.autostart.enable = true;
}
