{
  home-manager = {
    ## By default, Home Manager uses a private pkgs instance that is
    ## configured via the `home-manager.users.<name>.nixpkgs` options.
    ## The following option instead uses the global pkgs that is
    ## configured via the system level nixpkgs options; This saves an
    ## extra Nixpkgs evaluation, adds consistency, and removes the
    ## dependency on `NIX_PATH`, which is otherwise used for importing
    ## Nixpkgs.
    useGlobalPkgs = true;

    ## By default packages will be installed to `$HOME/.nix-profile` but
    ## they can be installed to `/etc/profiles` if the following is
    ## added to the system configuration. This option may become the
    ## default value in the future.
    useUserPackages = true;
  };
}
