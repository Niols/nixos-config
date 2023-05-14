{ nixpkgs, agenix, home-manager, secrets, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./hardware-configuration.nix
    ./boot.nix
    ./dancelor.nix
    ./environment.nix
    ./networking
    ./nix.nix
    ./nginx.nix
    ./ssh.nix
    ./syncthing.nix
    ./system.nix
    ./time.nix
    ./users.nix
    agenix.nixosModules.default
    home-manager.nixosModules.home-manager
    ./home-manager.nix
    { _module.args = { inherit secrets; }; }
  ];
}
