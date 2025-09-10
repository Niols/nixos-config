{ self, inputs, ... }:

{
  flake.nixosModules.gromit = {
    _module.args = {
      inherit (inputs) nixpkgs;
    };

    imports = [
      (import ../_common).laptop
      ../_modules/niols-motd.nix

      self.nixosModules.keys
      self.nixosModules.secrets

      inputs.agenix.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.nix-index-database.nixosModules.nix-index
      inputs.home-manager.nixosModules.home-manager
      ## Specific hardware optimisations for Lenovo ThinkPad X1 9th gen
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen

      ./network.nix
      ./legacy-configuration.nix
      ./syncthing.nix
    ];

    x_niols.hostPublicKey = self.keys.machines.gromit;

    nixpkgs.hostPlatform = "x86_64-linux";

    services.autorandr.x_niols.thisLaptopsFingerprint = "FIXME";

    niols-motd = {
      enable = true;
      hostname = "Gromit";
      hostcolour = "green";
    };

    programs.weylus = {
      enable = true;
      openFirewall = true;
      users = [ "niols" ];
    };

    home-manager.users = {
      niols = import ../home { inherit inputs; };
      root = import ../home { inherit inputs; };
    };
  };
}
