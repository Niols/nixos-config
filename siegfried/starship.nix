_: {
  imports = [ ../_modules/niols-starship.nix ];

  home-manager.users.niols.niols-starship = {
    enable = true;
    hostcolour = "yellow";
  };

  home-manager.users.root.niols-starship = {
    enable = true;
    hostcolour = "red";
  };
}
