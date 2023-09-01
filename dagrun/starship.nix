_: {
  home-manager.users.niols = _: {
    imports = [ ../_modules/niols-starship.nix ];

    niols-starship = {
      enable = true;
      hostcolour = "magenta";
    };
  };

  home-manager.users.root = _: {
    imports = [ ../_modules/niols-starship.nix ];

    niols-starship = {
      enable = true;
      hostcolour = "red";
    };
  };
}
