{ lib, ... }:

let
  inherit (lib) mkOption types;

in
{
  imports = [
    ./nix.nix
    ./packages.nix
  ];

  options.x_niols = {
    isServer = mkOption {
      description = ''
        Whether the machine is a server, instead of a personal computer.
      '';
      type = types.bool;
      default = false;
    };
  };
}
