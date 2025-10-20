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
    ./cloud.nix
    ./databases.nix
    ./dancelor.nix
    ./dns-server.nix
    ./ftp-server.nix
    ./git-server.nix
    ./hester.nix
    ./mastodon.nix
    ./matrix.nix
    ./medias.nix
    ./motd.nix
    ./network.nix
    ./nix-cache.nix
    ./ssh.nix
    ./syncthing.nix
    ./syncthing-server.nix # FIXME: merge?
    ./systemStateVersion.nix
    ./teamspeak.nix
    ./torrent.nix
    ./users.nix
    ./web.nix
  ];

  config = {
    x_niols.services = {
      call.enabledOn = "helga";
      cloud.enabledOn = "orianne";
      dancelor.enabledOn = "helga";
      ftp.enabledOn = "siegfried";
      git.enabledOn = "siegfried";
      mastodon.enabledOn = "siegfried";
      matrix.enabledOn = "helga";
      medias.enabledOn = "orianne";
      nix-cache.enabledOn = "siegfried";
      syncthing.enabledOn = "siegfried";
      teamspeak.enabledOn = "helga";
      torrent.enabledOn = "helga";
      web.enabledOn = "helga";
    };

    environment.systemPackages = config.x_niols.commonPackages;
  };

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
}
