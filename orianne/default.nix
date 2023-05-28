{ inputs, ... }:

{
  flake.nixosConfigurations.orianne = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./boot.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./jellyfin.nix
      ./nginx.nix
      ./public.nix
      ./ssh.nix
      ./system.nix
      ./packages.nix
      ./users.nix
    ];
  };
}
