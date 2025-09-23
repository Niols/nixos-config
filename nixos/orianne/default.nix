{ ... }:

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
      x_niols.hostPublicKey = keys.machines.${config.x_niols.thisDevicesNameLower};

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };
}
