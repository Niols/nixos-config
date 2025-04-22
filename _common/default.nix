## NOTE: Depending on the type of machine, we might not want to include exactly
## the same modules.

{
  server.imports = [
    ./databases.nix
    ./hester.nix
    ./nix.nix
    ./packages.nix
    ./ssh.nix
    ./syncthing.nix
  ];

  laptop.imports = [
    ./hester.nix
    ./nix.nix
    ./packages.nix
    ./syncthing.nix
  ];
}
