{ self, inputs, ... }:

{
  flake.nixosModules.siegfried =
    { config, keys, ... }:
    {
      imports = [
        ../_common/server.nix

        self.nixosModules.keys
        self.nixosModules.secrets

        ./ftp.nix
        ./git.nix
        ./hardware-configuration.nix
        ./mastodon.nix
        ./motd.nix
        ./nginx.nix
        ./starship.nix
        ./syncthing.nix
      ];

      x_niols.thisDevicesName = "Siegfried";
      x_niols.hostPublicKey = self.keys.machines.${config.x_niols.thisDevicesNameLower};

      users.users = {
        niols.hashedPasswordFile =
          config.age.secrets."password-${config.x_niols.thisDevicesNameLower}-niols".path;
        root.openssh.authorizedKeys.keys = [
          keys.github-actions."deploy-${config.x_niols.thisDevicesNameLower}"
        ];
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
