{ self, inputs, ... }:

{
  flake.nixosModules.dagrun =
    { config, keys, ... }:
    {
      imports = [
        (import ../_common).server

        # ../_modules/dancelor.nix
        # ../_modules/matrix.nix
        # ../_modules/torrent.nix

        # inputs.dancelor.nixosModules.dancelor

        ./hardware-configuration.nix
        ./motd.nix
        ./nginx.nix
        ./starship.nix
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
        { x_niols.hostPublicKey = self.keys.machines.dagrun; }
      ];

      networking = {
        hostName = "dagrun";
        domain = "niols.fr";
      };

      users.users = {
        niols.hashedPasswordFile = config.age.secrets.password-dagrun-niols.path;
        root.openssh.authorizedKeys.keys = [ keys.github-actions.deploy-dagrun ];
      };
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
