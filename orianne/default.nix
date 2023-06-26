{ inputs, ... }:

{
  flake.nixosConfigurations.orianne = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./boot.nix
      ./dancelor.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./jellyfin.nix
      ./motd.nix
      ./nginx.nix
      ./nix.nix
      ./public.nix
      ./ssh.nix
      ./starship.nix
      ./system.nix
      ./packages.nix
      ./users.nix
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      ./home-manager.nix
      { _module.args = { inherit (inputs) secrets nixpkgs; }; }
    ];
  };
}
