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
    ./autoreboot.nix
    ./boot.nix
    ./call.nix
    ./databases.nix
    ./dancelor.nix
    ./dns-server.nix
    ./hester.nix
    ./motd.nix
    ./network.nix
    ./nix-cache.nix
    ./packages.nix
    ./ssh.nix
    ./syncthing.nix
    ./systemStateVersion.nix
    ./users.nix
    ./web.nix
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
    dancelor.enabledOn = "helga";
    nix-cache.enabledOn = "siegfried";
    web.enabledOn = "helga";
  };
}
