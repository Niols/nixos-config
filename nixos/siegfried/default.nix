{
  flake.nixosModules.siegfried = {
    imports = [
      ../_common/server.nix

      ./ftp-server.nix
      ./git-server.nix
      ./hardware-configuration.nix
      ./mastodon.nix
      ./motd.nix
      ./nginx.nix
      ./syncthing.nix
    ];

    x_niols.thisDevicesName = "Siegfried";
    x_niols.thisDevicesColour = "yellow";

    x_niols.enableNixCache = true;
  };
}
