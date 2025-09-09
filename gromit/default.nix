{ self, inputs, ... }:

{
  flake.nixosModules.gromit =
    { config, ... }:
    {
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
      ];

      x_niols.thisDevicesName = "Gromit";
      x_niols.hostPublicKey = self.keys.machines.${config.x_niols.thisDevicesNameLower};
      x_niols.thisLaptopsWifiInterface = "wlp0s20f3";
      disko.devices.disk.main.device = "/dev/nvme0n1";
      x_niols.unencryptedOptSize = "200G";
      nixpkgs.hostPlatform = "x86_64-linux";

      home-manager.users = {
        niols = import ../home { inherit inputs; };
        root = import ../home { inherit inputs; };
      };
    };
}
