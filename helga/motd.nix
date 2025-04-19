{
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = "Helga"; # FIXME
    hostcolour = "magenta"; # FIXME
    noSwap = true;
  };
}
