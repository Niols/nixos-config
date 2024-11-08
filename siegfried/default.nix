{ inputs, ... }:

{
  flake.nixosConfigurations.siegfried = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./boot.nix
      ./ftp.nix
      ./git.nix
      ./hardware-configuration.nix
      ./hostname.nix
      ./mastodon.nix
      ./motd.nix
      ./nginx.nix
      ./nix.nix
      ./packages.nix
      ./ssh.nix
      ./starship.nix
      ./system.nix
      ./syncthing.nix
      ./teamspeak.nix
      ./users.nix
      ./web.nix
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      ./home-manager.nix
      {
        _module.args = {
          inherit (inputs) secrets nixpkgs;
        };
      }
      ../_common/hester.nix
    ];
  };
}
