{ self, ... }:

{
  flake.nixosModules.ahlaya =
    { config, inputs, ... }:
    {
      imports = [
        _common/laptop.nix
        ../_modules/niols-motd.nix

        ## Specific hardware optimisations for Lenovo ThinkPad X1 13th gen
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-13th-gen
      ];

      x_niols.thisDevicesName = "Ahlaya";
      x_niols.hostPublicKey = self.keys.machines.${config.x_niols.thisDevicesNameLower};
      x_niols.thisLaptopsWifiInterface = "wlp0s20f3";
      disko.devices.disk.main.device = "/dev/nvme0n1";
      nixpkgs.hostPlatform = "x86_64-linux";
      # services.autorandr.x_niols.thisLaptopsFingerprint = "FIXME";

      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users.niols.imports = [ ../home/laptop-niols.nix ];
    };
}
