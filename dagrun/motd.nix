_: {
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = "Dagrún";
    hostcolour = "magenta";
    noSwap = true;
  };
}
