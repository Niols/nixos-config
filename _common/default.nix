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

    ./hester.nix
    ./nix.nix
    ./packages.nix
    ./syncthing.nix

    ./both/boot.nix

    ./server/databases.nix
    ./server/ssh.nix
    ./server/users.nix
  ];

  laptop.imports = [
    x

    ./hester.nix
    ./nix.nix
    ./packages.nix
    ./syncthing.nix

    ./both/boot.nix

    ./laptop/users.nix
  ];
}
