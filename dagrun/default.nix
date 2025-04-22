{ self, inputs, ... }:

{
  flake.nixosModules.dagrun = {
    imports = [
      (import ../_common).server

      # ../_modules/dancelor.nix
      # ../_modules/matrix.nix

      ./boot.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./motd.nix
      ./nginx.nix
      ./starship.nix
      ./system.nix
      # ./torrent.nix
      ./users.nix
      inputs.agenix.nixosModules.default
      inputs.dancelor.nixosModules.default
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
      { x_niols.hostPublicKey = self.keys.machines.dagrun; }
      { x_niols.autoreboot.enable = true; }
    ];
  };

  flake.nixops4Resources.dagrun =
    { providers, ... }:
    {
      type = providers.local.exec;
      imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];

      ssh = {
        host = "141.145.213.115";
        opts = "";
        hostPublicKey = self.keys.machines.dagrun;
      };

      nixpkgs = inputs.nixpkgs;
      nixos.module = {
        imports = [ self.nixosModules.dagrun ];
      };
    };
}
