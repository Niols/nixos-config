{ lib, ... }: {
  ############################################################################
  ## Time zone and internationalisation

  time.timeZone = lib.mkDefault "Europe/Paris";
  services.automatic-timezoned.enable = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
}
