{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
    };

    nix-doom-emacs = {
      url = "github:nix-community/nix-doom-emacs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {

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
            extraSpecialArgs = inputs;
          };
        }
      ];
    };
  };
}
