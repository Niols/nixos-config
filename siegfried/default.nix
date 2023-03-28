{ nixpkgs, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./hardware-configuration.nix
    ./boot.nix
    ./networking
    ./nix.nix
    ./users.nix
    ./services.nix
    ./system.nix
    ./time.nix
    ./environment.nix
  ];
}
