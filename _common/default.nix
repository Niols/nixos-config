## NOTE: Depending on the type of machine, we might not want to include exactly
## the same modules.

{
  server.imports = [
    ./hester.nix
    ./nix.nix
    ./packages.nix
    ./syncthing.nix

    ./server/databases.nix
    ./server/ssh.nix
    ./server/users.nix
  ];

  laptop.imports = [
    ./hester.nix
    ./nix.nix
    ./packages.nix
    ./syncthing.nix

    ./laptop/users.nix
  ];
}
