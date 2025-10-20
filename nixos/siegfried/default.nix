{
  flake.nixosModules.siegfried = {
    imports = [
      ../_common/server.nix

      ./hardware-configuration.nix
      ./nginx.nix
      ./syncthing.nix
    ];

    x_niols.thisMachinesName = "siegfried";
    x_niols.thisMachinesColour = "yellow";
  };
}
