{ nixpkgs, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./hardware-configuration.nix
    ./configuration.nix
    ./boot
    ./networking
    ./nix
    ./users
    ./services
    ./system
  ];
}
