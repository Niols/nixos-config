{
  config,
  lib,
  machines,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    attrNames
    ;

  inherit (config.x_niols) thisMachinesName;

in
{
  imports = [
    ./boot.nix
    ./hester.nix
    ./motd.nix
    ./network.nix
    ./nix-cache.nix
    ./packages.nix
    ./ssh.nix
    ./syncthing.nix
    ./users.nix
  ];

  options.x_niols = {
    thisMachinesName = mkOption {
      description = ''
        The name of the machine, eg. “wallace”. It should be capitalised. It
        should only contain ASCII characters.
      '';
      type = types.enum (attrNames machines.all);
    };

    services = mkOption {
      description = ''
        Map specifying on which server which service should be running.
      '';
      example = {
        nix-cache = "siegfried";
        cloud = "orianne";
      };
      type = types.attrsOf (
        types.submodule (
          { config, ... }:
          {
            options = {
              enabledOn = mkOption {
                description = ''
                  On which server this service should be running, or `null` if the service should be disabled.
                '';
                type = types.nullOr (types.enum (attrNames machines.servers));
              };
              enabledOnAnyServer = mkOption {
                description = ''
                  Whether the service is enabled at all.
                '';
                type = types.bool;
                default = config.enabledOn != null;
                readOnly = true;
              };
              enabledOnThisServer = mkOption {
                description = ''
                  Whether the service is running on the machine for which we are currently evaluating the configuration.
                '';
                type = types.bool;
                default = config.enabledOn == thisMachinesName;
                readOnly = true;
              };
            };
          }
        )
      );
    };
  };

  config.x_niols.services = {
    call.enabledOn = "helga";
    nix-cache.enabledOn = "siegfried";
  };

  ## This value determines the NixOS release from which the default settings for
  ## stateful data, like file locations and database versions on your system
  ## were taken. It's perfectly fine and recommended to leave this value at the
  ## release version of the first install of this system. Before changing this
  ## value read the documentation for this option (e.g. man configuration.nix or
  ## on https://nixos.org/nixos/options.html).
  config.system.stateVersion = "23.11"; # Did you read the comment?
}
