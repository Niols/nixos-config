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
      services.autorandr.x_niols.thisLaptopsFingerprint = "00ffffffffffff0009e5ca0c0000000003220104a51e1378078b94a3564d9b240d515400000001010101010101010101010101010101333f80dc70b03c40302036002ebc1000001a000000fd00283c4c4c10010a202020202020000000fe00424f452043510a202020202020000000fc004e4531343057554d2d4e364d0a018d7020790200250109f77702f77702283c80810015741a00000301283c00006a496a493c000000008d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b790";
      x_niols.enableWorkUser = true;

      home-manager.users.niols.imports = [ ../home/laptop-niols.nix ];
      home-manager.users.work.imports = [ ../home/laptop-work.nix ];
    };
}
