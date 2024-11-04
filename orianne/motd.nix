{
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = "Orianne";
    hostcolour = "cyan";
    noSwap = true;
  };
}
