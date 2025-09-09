## NOTE: Depending on the type of machine, we might not want to include exactly
## the same modules.

let
  x = {
    # This value determines the NixOS release from which the default settings
    # for stateful data, like file locations and database versions on your
    # system were taken. It's perfectly fine and recommended to leave this value
    # at the release version of the first install of this system. Before
    # changing this value read the documentation for this option (e.g. man
    # configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "23.11"; # Did you read the comment?
  };

in
{
  server.imports = [
    x

    ./both/hester.nix
    ./both/home-manager.nix
    ./both/nix.nix
    ./both/packages.nix
    ./both/ssh.nix
    ./both/syncthing.nix

    ./server/autoreboot.nix
    ./server/boot.nix
    ./server/databases.nix
    ./server/home-manager.nix
    ./server/nix.nix
    ./server/ssh.nix
    ./server/users.nix
  ];

  laptop.imports = [
    x

    ./both/hester.nix
    ./both/home-manager.nix
    ./both/nix.nix
    ./both/packages.nix
    ./both/ssh.nix
    ./both/syncthing.nix

    ./laptop/autorandr.nix
    ./laptop/boot.nix
    ./laptop/disk-config.nix
    ./laptop/nix.nix
    ./laptop/packages
    ./laptop/timezone.nix
    ./laptop/udev.nix
    ./laptop/users.nix
    ./laptop/xserver.nix
  ];
}
