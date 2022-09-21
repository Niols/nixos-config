{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {

    nixosConfigurations.wallace = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        ./legacy-configuration.nix
        ./packages.nix

        home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.niols = import ./home.nix;
          };
          ## FIXME: use home-manager.extraSpecialArgs
          ## to pass arguments to home.nix
        }
      ];
    };
  };
}
