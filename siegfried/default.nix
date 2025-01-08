{ self, inputs, ... }:

{
  flake.nixosModules.siegfried = {
    imports = [
      ../_common

      ./boot.nix
      ./ftp.nix
      ./git.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./mastodon.nix
      ./motd.nix
      ./nginx.nix
      ./nix.nix
      ./packages.nix
      ./ssh.nix
      ./starship.nix
      ./system.nix
      ./syncthing.nix
      ./teamspeak.nix
      ./users.nix
      ./web.nix
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      ./home-manager.nix
      {
        _module.args = {
          inherit (inputs) nixpkgs;
        };
      }
      self.nixosModules.keys
      self.nixosModules.secrets
      { x_niols.hostPublicKey = self.keys.machines.siegfried; }
    ];
  };

  flake.nixops4Resources.siegfried =
    { providers, ... }:
    {
      type = providers.local.exec;
      imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];

      ssh = {
        host = "158.178.201.160";
        opts = "";
        hostPublicKey = self.keys.machines.siegfried;
      };

      nixpkgs = inputs.nixpkgs;
      nixos.module = {
        imports = [ self.nixosModules.siegfried ];
      };
    };
}
