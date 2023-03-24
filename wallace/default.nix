inputs@{ nixpkgs, nixos-hardware, opam-nix, home-manager, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [

    ## A module providing overlays that will apply to the `pkgs` received by
    ## all the subsequent modules.
    (import ./overlays.nix inputs)

    ./hardware-configuration.nix

    ## Specific hardware optimisations for Lenovo ThinkPad X1 9th gen
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen

    ./legacy-configuration.nix
    (import ./packages.nix { opam-nix = opam-nix.lib.x86_64-linux; })

    {
      nix.registry.nixpkgs.flake = nixpkgs;
    }

    home-manager.nixosModules.home-manager {
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

        users = {
          niols = import ./home;
          root = import ./home;
        };

        ## The following option gives Home Manager an access to this file's
        ## inputs through the `specialArgs` option, eg.
        ## `specialArgs.nix-doom-emacs`.
        extraSpecialArgs = inputs;
      };
    }
  ];
}
