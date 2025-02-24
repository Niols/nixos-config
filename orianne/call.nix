{ config, ... }:

let
  turnPort = 1194;

in
{
  services.galene = {
    enable = true;
    insecure = true; # because behind nginx
    turnAddress = ":${toString turnPort}";
    recordingsDir = "/hester/services/galene/recordings";
    httpPort = 8443;
  };

  networking.firewall = {
    ## NOTE: We do not open `services.galene.httpPort` because we run it behind
    ## a reverse proxy.
    ##
    ## NOTE: The TURN port MUST be open for TCP, and MAY be open for UDP for
    ## increased performances.

    allowedTCPPorts = [
      turnPort
      config.services.galene.httpPort # # FIXME: proxy
    ];
    allowedUDPPorts = [
      turnPort
      config.services.galene.httpPort # # FIXME: proxy
    ];
    allowedUDPPortRanges = [
      # # FIXME: pass `-udp-range` to Galène
      {
        from = 56000;
        to = 57000;
      }
    ];
  };

  _common.hester.fileSystems.services-galene = {
    path = "/services/galene";
    uid = config.services.galene.user;
    gid = config.services.galene.group;
  };

  ############################################################################
  ## Reverse proxy

  services.nginx.virtualHosts.call = {
    serverName = "call.niols.fr";

    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.galene.httpPort}";
      recommendedProxySettings = true;
    };

    locations."/ws" = {
      proxyPass = "http://127.0.0.1:${toString config.services.galene.httpPort}";
      recommendedProxySettings = true;
      extraConfig = ''
        ## Add some extra headers to handle Websocket connections correctly.
        ## Source: https://www.nginx.com/blog/websocket-nginx/
        proxy_buffering off;
        proxy_http_version 1.1;

        proxy_set_header = "Upgrade $http_upgrade";
        proxy_set_header = "Connection Upgrade";
      '';
    };
  };

  ############################################################################
  ## Backups

  services.borgbackup.jobs.galene = {
    paths = config.services.galene.stateDir;
    repo = "ssh://u363090@hester.niols.fr:23/./backups/galene";
    startAt = "*-*-* 06:00:00";
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.age.secrets.hester-galene-backup-repokey.path}";
    };
    environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-galene-backup-identity.path}";
  };
}
