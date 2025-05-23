{ config, secrets, ... }:

{
  services.nginx.virtualHosts."niols.fr" = {
    serverName = "niols.fr";
    serverAliases = [
      "www.niols.fr"
      "nicolas.jeannerod.fr"
      "www.nicolas.jeannerod.fr"
    ];

    forceSSL = true;
    enableACME = true;

    root = "/hester/services/web/niols.fr";
    locations."/" = {
      index = "index.html";
      tryFiles = "$uri $uri/ =404";
    };

    ## Well-known entries for Matrix. They are necessary because the domain is
    ## `niols.fr` (eg. in `@niols:niols.fr`) but the server name is
    ## `matrix.niols.fr`. It might even be on a different machine. `server` is
    ## for federation and `client` is for Matrix clients.
    ## FIXME: Move this closer to Matrix, but this is on another machine.
    locations."= /.well-known/matrix/server".extraConfig = ''
      default_type application/json;
      add_header Access-Control-Allow-Origin *;
      return 200 '{"m.server": "matrix.niols.fr:443"}';
      ## Repeat headers from the server context.
      add_header Strict-Transport-Security $hsts_header;
      add_header Referrer-Policy origin-when-cross-origin;
      add_header X-Frame-Options DENY;
      add_header X-Content-Type-Options nosniff;
      add_header X-XSS-Protection "1; mode=block";
    '';
    locations."= /.well-known/matrix/client".extraConfig = ''
      default_type application/json;
      add_header Access-Control-Allow-Origin *;
      return 200 '{"m.homeserver": {"base_url": "https://matrix.niols.fr/"}}';
      ## Repeat headers from the server context.
      add_header Strict-Transport-Security $hsts_header;
      add_header Referrer-Policy origin-when-cross-origin;
      add_header X-Frame-Options DENY;
      add_header X-Content-Type-Options nosniff;
      add_header X-XSS-Protection "1; mode=block";
    '';
  };

  systemd.services.nginx.unitConfig = {
    requires = [ "hester.automount" ];
    after = [ "hester.automount" ];
  };

  _common.hester.fileSystems = {
    services-web = {
      path = "/services/web";
      worldReadable = true;
    };
  };

  ############################################################################
  ## Daily backup

  services.borgbackup.jobs.web = {
    startAt = "*-*-* 05:00:00";

    paths = [ "/hester/services/web" ];

    repo = "ssh://u363090@hester.niols.fr:23/./backups/web";
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.age.secrets.hester-web-backup-repokey.path}";
    };
    environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-web-backup-identity.path}";
  };

  systemd.services.borgbackup-job-web.unitConfig.RequiresMountsFor = "/hester";
}
