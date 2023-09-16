_: {
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = "Emeline";
    hostcolour = "blue";
    noSwap = true;
  };
}
