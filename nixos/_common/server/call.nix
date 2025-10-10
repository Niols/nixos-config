{
  config,
  lib,
  machines,
  ...
}:

let
  inherit (builtins)
    toFile
    toJSON
    ;

  inherit (lib)
    mkMerge
    mkIf
    mkOption
    concatMap
    mapAttrsToList
    listToAttrs
    ;

  turnPort = 1194;

in
{
  options.services.galene = {
    settings.data = mkOption { };
    settings.groups = mkOption { };
  };

  config = mkMerge [
    (mkIf config.x_niols.services.call.enabledOnAnyServer {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        call  IN  CNAME  ${config.x_niols.services.call.enabledOn}
      '';
    })

    (mkIf config.x_niols.services.call.enabledOnThisServer {
      services.galene = {
        enable = true;
        insecure = true;

        ## We need to expose the public IP here, because if the server is a VPS,
        ## then Galene will only manage to see the internal IP and not the
        ## public one. Galene's documentation says:
        ##
        ## > if the value of this option is a socket address, such as
        ## > 203.0.113.1:1194, then the TURN server will listen on all addresses
        ## > of the local host but assume that the address seen by the clients
        ## > is the one given in the option; this may be useful when running
        ## > behind NAT with port forwarding set up.
        ##
        turnAddress = "${
          machines.servers.${config.x_niols.services.call.enabledOn}.ipv4
        }:${toString turnPort}";

        settings.data.config = {
          proxyUrl = "https://call.niols.fr/";
          canonicalHost = "call.niols.fr";
          writableGroups = false;
        };

        ## FIXME: Handle secrets and load groups via secrets.
        settings.groups.scd = {
          displayName = "Scottish Country Dancing";
          public = true; # list on landing page
          wildcard-user = {
            password.type = "wildcard"; # any user with any password
            permissions = "present";
          };
          allow-recording = false;
        };

        dataDir = "/etc/galene/data";
        groupsDir = "/etc/galene/groups";
      };

      environment.etc = listToAttrs (
        concatMap
          (
            category:
            mapAttrsToList (fileName: fileConfig: {
              name = "galene/${category}/${fileName}.json";
              value.source = toFile "${fileName}.json" (toJSON fileConfig);
            }) config.services.galene.settings.${category}
          )
          [
            "data"
            "groups"
          ]
      );

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."call.niols.fr" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.galene.httpPort}";
            proxyWebsockets = true;
          };
        };
      };

      ## Open ports for the TURN server.
      networking.firewall.allowedTCPPorts = [ turnPort ];
      networking.firewall.allowedUDPPorts = [ turnPort ];

      ## Open WebRTC UDP ports. REVIEW: reduce?
      networking.firewall.allowedUDPPortRanges = [
        {
          from = 1024;
          to = 65535;
        }
      ];
    })
  ];
}
