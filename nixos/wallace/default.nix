{ self, inputs, ... }:

{
  flake.nixosModules.wallace =
    { config, lib, ... }:
    {
      imports = [
        ../_common/laptop.nix
        ../../_modules/niols-motd.nix

        ## Specific hardware optimisations for Lenovo ThinkPad X1 9th gen
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
      ];

      x_niols.thisDevicesName = "Wallace";
      x_niols.hostPublicKey = self.keys.machines.${config.x_niols.thisDevicesNameLower};
      x_niols.thisLaptopsWifiInterface = "wlp0s20f3";

      nixpkgs.hostPlatform = "x86_64-linux";

      services.autorandr.x_niols.thisLaptopsFingerprint = "00ffffffffffff000e6f031400000000001e0104b51e1378032594af5042b0250d4e550000000101010101010101010101010101010180e800a0f0605090302036002ebd10000018000000fd00303c95953c010a202020202020000000fe0043534f542054330a2020202020000000fe004d4e453030375a41312d320a2001a102030f00e3058000e60605016a6a24000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a";

      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users.niols.imports = [ ../../home/laptop-niols.nix ];

      ############################################################################
      ## Hardware configuration
      ##
      ## NOTE: Wallace was installed pre-Disko and therefore we will handle its
      ## disk configuration by hand. New laptops should not use this.

      x_niols.enableDiskoConfig = false;

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/root";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/1873-B7F4";
          fsType = "vfat";
        };
      };

      swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

      boot.initrd.luks.devices = {
        crypt = {
          device = "/dev/nvme0n1p2";
          preLVM = true;
        };
      };

      ############################################################################
      ## Hester configuration
      ##
      ## TODO: For new laptops, use the new better common interface.
      fileSystems."/hester" = {
        device = "//hester.niols.fr/backup";
        fsType = "cifs";
        options = [
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=60"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"
          "credentials=${config.age.secrets.hester-samba-credentials.path}"
          "gid=hester"
          "dir_mode=0775"
          "file_mode=0664"
          "cache=loose"
        ];
      };
      users.groups.hester.members = [ "niols" ];

      ############################################################################
      ## This value determines the NixOS release from which the default
      ## settings for stateful data, like file locations and database
      ## versions on your system were taken. It‘s perfectly fine and
      ## recommended to leave this value at the release version of the
      ## first install of this system.  Before changing this value read
      ## the documentation for this option (e.g. man configuration.nix or
      ## on https://nixos.org/nixos/options.html).
      system.stateVersion = lib.mkForce "21.05"; # Did you read the comment?
      # ^ FIXME: unify with other system.stateVersion in _common.
    };
}
