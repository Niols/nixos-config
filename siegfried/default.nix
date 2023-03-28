inputs@{ nixpkgs, nixos-hardware, opam-nix, home-manager, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./configuration.nix ];
}
