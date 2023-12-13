{ inputs, ... }:

{
  flake.nixosConfigurations.orianne = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./boot.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./media.nix
      ./motd.nix
      ./nginx.nix
      ./nix.nix
      ./packages.nix
      ./ssh.nix
      ./starship.nix
      ./storage.nix
      ./system.nix
      ./users.nix
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      ./home-manager.nix
      { _module.args = { inherit (inputs) secrets nixpkgs; }; }
    ];
  };
}
