_: {
  ############################################################################
  ## Time zone and internationalisation
  ##
  ## List all available timezones with:
  ##
  ##     timedatectl list-timezones
  ##

  # time.timeZone = "Europe/London";
  time.timeZone = "Europe/Paris";
  # time.timeZone = "Iceland";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
}
