{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;

    ## NOTE: It is important to enable Bash so that Home Manager active
    ## properly. Otherwise, see Home Manager's documentation.

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
