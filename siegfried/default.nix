{ nixpkgs, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./configuration.nix ./boot.nix ./hostName.nix ./networking.nix ];
}
