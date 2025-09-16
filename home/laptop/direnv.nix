{
  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    bash.enable = true;
  };
}

## REVIEW: It is possible to make direnv quiet by setting the environment
## variable DIRENV_LOG_FORMAT to the empty string. Do we want that?
