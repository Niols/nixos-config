{ nixpkgs, ... }:

nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  modules = [
    ./boot.nix
    ./hardware-configuration.nix
    ./hostname.nix
    ./networking.nix
    ./ssh.nix
    ./system.nix
    ./time.nix
    ./users.nix
  ];
}
