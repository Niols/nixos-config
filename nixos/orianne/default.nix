{ self, ... }:

{
  flake.nixosModules.orianne =
    { config, keys, ... }:
    {
      imports = [
        ../_common/server.nix

        ./cloud.nix
        ./hardware-configuration.nix
        ./medias.nix
        ./motd.nix
        ./nginx.nix
        ./starship.nix
        ./storage.nix
      ];

      x_niols.thisDevicesName = "Orianne";
      x_niols.hostPublicKey = self.keys.machines.${config.x_niols.thisDevicesNameLower};

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      users.users = {
        niols.hashedPasswordFile =
          config.age.secrets."password-${config.x_niols.thisDevicesNameLower}-niols".path;
        root.openssh.authorizedKeys.keys = [ keys.github-actions ];
      };
    };
}
