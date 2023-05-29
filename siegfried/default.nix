{ inputs, ... }:

{
  flake.nixosConfigurations.siegfried = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./hardware-configuration.nix
      ./boot.nix
      ./dancelor.nix
      ./environment.nix
      ./hostname.nix
      ./motd.nix
      ./networking.nix
      ./nix.nix
      ./nginx.nix
      ./public.nix
      ./ssh.nix
      ./syncthing.nix
      ./system.nix
      ./time.nix
      ./users.nix
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      ./home-manager.nix
      { _module.args = { inherit (inputs) secrets nixpkgs; }; }
    ];
  };
}
