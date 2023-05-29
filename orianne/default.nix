{ inputs, ... }:

{
  flake.nixosConfigurations.orianne = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./boot.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./jellyfin.nix
      ./motd.nix
      ./nginx.nix
      ./public.nix
      ./ssh.nix
      ./starship.nix
      ./system.nix
      ./packages.nix
      ./users.nix
      inputs.home-manager.nixosModules.home-manager
      ./home-manager.nix
    ];
  };
}
