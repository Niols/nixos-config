{ self, inputs, ... }:

{
  flake.nixosModules.helga = {
    imports = [
      (import ../_common).server

      ../_modules/dancelor.nix
      ../_modules/matrix.nix
      ../_modules/teamspeak.nix
      ../_modules/torrent.nix
      ../_modules/web.nix

      inputs.dancelor.nixosModules.default

      ./boot.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./motd.nix
      ./nginx.nix
      ./starship.nix
      ./system.nix
      ./users.nix
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      ./home-manager.nix
      {
        _module.args = {
          inherit (inputs) nixpkgs;
        };
      }
      self.nixosModules.x_niols
      self.nixosModules.keys
      self.nixosModules.secrets
      { x_niols.hostPublicKey = self.keys.machines.helga; }
      { x_niols.autoreboot.enable = true; }
    ];
  };

  flake.nixops4Resources.helga =
    { providers, ... }:
    {
      type = providers.local.exec;
      imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];

      ssh = {
        host = "188.245.212.11";
        opts = "";
        hostPublicKey = self.keys.machines.helga;
      };

      nixpkgs = inputs.nixpkgs;
      nixos.module = {
        imports = [ self.nixosModules.helga ];
      };
    };
}
