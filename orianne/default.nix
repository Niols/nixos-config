{ inputs, ... }:

{
  flake.nixosModules.orianne = {
    imports = [
      ../_common

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

  # flake.nixops4Resources.orianne =
  #   { providers, ... }:
  #   {
  #     type = providers.local.exec;
  #     imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];

  #     ssh = {
  #       host = "89.168.38.231";
  #       opts = "";
  #       hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBUAVk+u2veGt3xmwhsbNP8KVIcnnYmzoBbwswdIxKHO";
  #     };

  #     nixpkgs = inputs.nixpkgs;
  #     nixos.module = {
  #       imports = [ self.nixosModules.orianne ];
  #     };
  #   };
}
