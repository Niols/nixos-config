{ self, ... }:

{
  flake.nixosModules.siegfried =
    { config, keys, ... }:
    {
      imports = [
        ../_common/server.nix

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
        root.openssh.authorizedKeys.keys = [ keys.github-actions ];
      };
    };
}
