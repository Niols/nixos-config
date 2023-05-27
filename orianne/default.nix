{ nixpkgs, ... }:

nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  modules = [
    ./boot.nix
    ./hardware-configuration.nix
    ./hostname.nix
    ./jellyfin.nix
    ./ssh.nix
    ./system.nix
    ./packages.nix
    ./users.nix

    ## FIXME:
    { networking.firewall.enable = false; }
  ];
}
