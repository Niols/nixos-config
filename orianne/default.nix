{ self, inputs, ... }:

{
  flake.nixosModules.orianne = {
    imports = [
      ./boot.nix
      ./cloud.nix
      ./databases.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./medias.nix
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
      {
        _module.args = {
          inherit (inputs) secrets nixpkgs;
        };
      }
    ];
  };

  flake.nixosConfigurations.orianne = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [ self.nixosModules.orianne ];
  };
}
