{ config, lib, ... }:

{
  imports = [ ../../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = lib.toSentenceCase config.x_niols.thisMachinesName;
    hostcolour = config.x_niols.thisMachinesColour;
    noSwap = true;
  };
}
