_: {
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = "Dagrún";
    hostcolour = "purple";
    noSwap = true;
  };
}
