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
      ./nix.nix
      ./public.nix
      ./ssh.nix
      ./system.nix
      ./packages.nix
      ./users.nix
      { _module.args = { inherit (inputs) nixpkgs; }; }
    ];
  };
}
