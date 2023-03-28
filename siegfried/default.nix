{ nixpkgs, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./hardware-configuration.nix
    ./boot
    ./networking
    ./nix
    ./users
    ./services
    ./system
    ./time
    ./environment.nix
  ];
}
