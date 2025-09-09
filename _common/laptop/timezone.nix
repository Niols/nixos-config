{
  ############################################################################
  ## Time zone and internationalisation

  ## I have tried `automatic-timezoned` that does not get the right timezone
  ## when I am in Iceland and `tzupdate` that gets it right but does not update
  ## the actual timezone (visible in `timedatectl`). This is the combination
  ## that works for me in Iceland:
  services.geoclue2.enable = true;
  services.localtimed.enable = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
}
