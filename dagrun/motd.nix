{
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = "Dagrun"; # FIXME
    hostcolour = "magenta";
    noSwap = true;
  };
}
