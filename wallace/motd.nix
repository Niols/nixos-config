_: {
  imports = [ ../_modules/niols-motd.nix ];

  niols-motd = {
    enable = true;
    hostname = "Wallace";
    hostcolour = "green";
  };
}
