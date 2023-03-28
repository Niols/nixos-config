{ nixpkgs, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./hardware-configuration.nix
    ./boot.nix
    ./environment.nix
    ./networking
    ./nix.nix
    ./services.nix
    ./system.nix
    ./time.nix
    ./users.nix
  ];
}
