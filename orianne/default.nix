{ nixpkgs, ... }:

nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  modules = [
    ./boot.nix
    ./hardware-configuration.nix
    ./ssh.nix
    ./system.nix
    ./users.nix
  ];
}
