{ self, ... }:

{
  flake.nixosModules.gromit =
    { config, inputs, ... }:
    {
      imports = [
        ../_common/laptop.nix
        ../_modules/niols-motd.nix

        ## Specific hardware optimisations for Lenovo ThinkPad X1 9th gen
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
      ];

      x_niols.thisDevicesName = "Gromit";
      x_niols.hostPublicKey = self.keys.machines.${config.x_niols.thisDevicesNameLower};
      x_niols.thisLaptopsWifiInterface = "wlp0s20f3";
      disko.devices.disk.main.device = "/dev/nvme0n1";
      x_niols.unencryptedOptSize = "200G";
      nixpkgs.hostPlatform = "x86_64-linux";
      services.autorandr.x_niols.thisLaptopsFingerprint = "00ffffffffffff000e6f031400000000001e0104b51e137803249daf5043b0250e4f540000000101010101010101010101010101010180e800a0f0605090302036002ebd10000018000000fd00303c95953c010a202020202020000000fe0043534f542054330a2020202020000000fe004d4e453030375a41312d320a20019702030f00e3058000e60605016a6a24000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a";

      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users = {
        niols.imports = [ ../home ];
        root.imports = [ ../home ];
      };
    };
}
