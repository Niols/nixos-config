{ config, lib, ... }:

let
  inherit (lib) mkOption toLower;

in
{
  options.x_niols = {
    thisDevicesName = mkOption {
      description = ''
        The name of the device, eg. “Wallace”. It should be capitalised. It
        should only contain ASCII characters.
      '';
    };

    thisDevicesNameLower = mkOption {
      description = ''
        The name of the device, lowercase. This should not be set manually and
        only exists as a convenience for the rest of the code.
      '';
      default = toLower config.x_niols.thisDevicesName;
    };
  };
}
