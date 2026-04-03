{
  flake.nixosModules.anastasia =
    { modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ../_common/server.nix
      ];

      x_niols.thisMachinesName = "anastasia";
      x_niols.thisMachinesColour = "purple";
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
