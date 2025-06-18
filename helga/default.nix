{ self, inputs, ... }:

{
  flake.nixosModules.helga =
    { config, keys, ... }:
    {
      imports = [
        (import ../_common).server

        ../_modules/dancelor.nix
        ../_modules/matrix.nix
        ../_modules/teamspeak.nix
        ../_modules/torrent.nix
        ../_modules/web.nix

        inputs.dancelor.nixosModules.default

        ./hardware-configuration.nix
        ./hostname.nix
        ./motd.nix
        ./nginx.nix
        ./starship.nix
        ./system.nix
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

      users.users = {
        niols.hashedPasswordFile = config.age.secrets.password-helga-niols.path;
        root.openssh.authorizedKeys.keys = [ keys.github-actions.deploy-helga ];
      };
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
