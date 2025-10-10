{
  flake.nixosModules.orianne = {
    imports = [
      ../_common/server.nix

      ./cloud.nix
      ./hardware-configuration.nix
      ./medias.nix
      ./nginx.nix
      ./storage.nix
    ];

    x_niols.thisMachinesName = "orianne";
    x_niols.thisMachinesColour = "cyan";

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
