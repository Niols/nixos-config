{ self, inputs, ... }:

{
  flake.nixosModules.siegfried = {
    imports = [
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
          inherit (inputs) secrets nixpkgs;
        };
      }
      ../_common/hester.nix
    ];
  };

  flake.nixosConfigurations.siegfried = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.siegfried ];
  };

  nixops4Deployments.siegfried =
    { providers, ... }:
    {
      providers.local = inputs.nixops4-nixos.modules.nixops4Provider.local;

      resources.siegfried = {
        type = providers.local.exec;
        imports = [ inputs.nixops4-nixos.modules.nixops4Resource.nixos ];

        ssh = {
          host = "158.178.201.160";
          opts = "";
          hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHKNHteo/srejmG5pgYRvmsZXqA+NJKCjI9H3f7l6TUb";
        };

        nixpkgs = inputs.nixpkgs;
        nixos.module = {
          imports = [ self.nixosModules.siegfried ];
        };
      };
    };
}
