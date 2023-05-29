_: {
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;

    users.niols = {
      home.stateVersion = "21.05";
      programs.home-manager.enable = true;
      programs.bash.enable = true;
    };

    users.root = {
      home.stateVersion = "21.05";
      programs.home-manager.enable = true;
      programs.bash.enable = true;
    };
  };
}
