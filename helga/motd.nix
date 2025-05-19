{
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = "Helga";
    hostcolour = "blue";
    noSwap = true;
  };
}
