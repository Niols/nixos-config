{ config, secrets, ... }:

let
  localhost = "127.0.0.1";
  port = 1453;
  ## ^ chosen randomly

in {
  services.postgresql = {
    ensureDatabases = [ "vaultwarden" ];
    ensureUsers = [{
      name = "vaultwarden";
      ensureDBOwnership = true;
    }];
    ## All databases are backed up daily. See `databases.nix`.
  };

  services.vaultwarden = {
    enable = true;

    dbBackend = "postgresql";

    config = {
      DATABASE_URL = "postgresql://${localhost}";

      ## Web interface
      ROCKET_ADDRESS = localhost;
      ROCKET_PORT = port;
      SIGNUPS_ALLOWED = false;

      ## Mailing
      SMTP_HOST = "mail.infomaniak.com";
      SMTP_FROM = "no-reply@niols.fr";
      SMTP_PORT = 465;
      SMTP_SECURITY = "force_tls";
      SMTP_USERNAME = "no-reply@niols.fr";
    };

    environmentFile = config.age.secrets.vaultwarden-environment.path;
  };

  age.secrets.vaultwarden-environment.file =
    "${secrets}/vaultwarden-environment.age";

  services.nginx.virtualHosts.vault = {
    serverName = "vault.niols.fr";
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "http://${localhost}:${builtins.toString port}";
  };
}
