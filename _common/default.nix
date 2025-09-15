## NOTE: Depending on the type of machine, we might not want to include exactly
## the same modules.

{
  server.imports = [
    ./both/constants.nix
    ./both/hester.nix
    ./both/home-manager.nix
    ./both/network.nix
    ./both/nix.nix
    ./both/packages.nix
    ./both/ssh.nix
    ./both/syncthing.nix
    ./both/systemStateVersion.nix

    ./server/autoreboot.nix
    ./server/boot.nix
    ./server/databases.nix
    ./server/home-manager.nix
    ./server/nix.nix
    ./server/ssh.nix
    ./server/users.nix
  ];

  laptop.imports = [
    ./both/constants.nix
    ./both/hester.nix
    ./both/home-manager.nix
    ./both/network.nix
    ./both/nix.nix
    ./both/packages.nix
    ./both/ssh.nix
    ./both/syncthing.nix
    ./both/systemStateVersion.nix

    ./laptop/autorandr.nix
    ./laptop/boot.nix
    ./laptop/hardware.nix
    ./laptop/network.nix
    ./laptop/nix.nix
    ./laptop/packages
    ./laptop/syncthing.nix
    ./laptop/timezone.nix
    ./laptop/udev.nix
    ./laptop/users.nix
    ./laptop/xserver.nix
    ./laptop/zzz.nix
  ];
}
