{
  flake.nixosModules.siegfried = {
    imports = [
      ../_common/server.nix

      ./ftp-server.nix
      ./git-server.nix
      ./hardware-configuration.nix
      ./mastodon.nix
      ./nginx.nix
      ./syncthing.nix
    ];

    x_niols.thisMachinesName = "siegfried";
    x_niols.thisMachinesColour = "yellow";
  };
}
