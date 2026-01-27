{
  flake.nixosModules.helga =
    { modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ../_common/server.nix
        ./nginx.nix
      ];

      x_niols.thisMachinesName = "helga";
      x_niols.thisMachinesColour = "blue";
      x_niols.enableNiolsUser = true;

      nixpkgs.hostPlatform = "x86_64-linux";

      boot = {
        loader.grub.device = "/dev/sda";
        initrd = {
          availableKernelModules = [
            "ata_piix"
            "uhci_hcd"
            "xen_blkfront"
            "vmw_pvscsi"
          ];
          kernelModules = [ "nvme" ];
        };
      };

      fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
      };
    };
}
