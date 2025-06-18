{ self, inputs, ... }:

{
  flake.nixosModules.siegfried =
    { config, keys, ... }:
    {
      imports = [
        (import ../_common).server

        # ../_modules/web.nix
        # ../_modules/teamspeak.nix

        ./ftp.nix
        ./git.nix
        ./hardware-configuration.nix
        ./hostname.nix
        ./mastodon.nix
        ./motd.nix
        ./nginx.nix
        ./starship.nix
        ./system.nix
        ./syncthing.nix
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
        { x_niols.hostPublicKey = self.keys.machines.siegfried; }
        { x_niols.autoreboot.enable = true; }
      ];

      users.users = {
        niols.hashedPasswordFile = config.age.secrets.password-siegfried-niols.path;
        root.openssh.authorizedKeys.keys = [ keys.github-actions.deploy-siegfried ];
      };
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
