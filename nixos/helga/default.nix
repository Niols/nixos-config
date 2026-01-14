{
  flake.nixosModules.helga =
    { modulesPath, pkgs, ... }:
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

      systemd.services.wg-socat-server = {
        description = "Socat WireGuard TCP to UDP forwarder";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat -d -d TCP4-LISTEN:4433,reuseaddr,fork UDP4:backend-vpn.ahrefs.net:4433";
          Restart = "always";
        };
      };
      networking.firewall.allowedTCPPorts = [ 4433 ];
    };
}
