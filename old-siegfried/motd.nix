_: {
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = "Siegfried";
    hostcolour = "yellow";
  };
}
