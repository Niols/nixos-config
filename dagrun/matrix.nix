{ config, secrets, ... }:

{
  services.postgresql = {
    ensureUsers = [{ name = "matrix-synapse"; }];
    ## Database `matrix-synapse` has to be created manually. Be careful with the
    ## collation. Refer to the documentation:
    ## https://github.com/matrix-org/synapse/blob/be65a8ec0195955c15fdb179c9158b187638e39a/docs/postgres.md#fixing-incorrect-collate-or-ctype
  };

  services.nginx.virtualHosts.matrix = {
    serverName = "matrix.niols.fr";

    enableACME = true;
    forceSSL = true;

    locations = {
      ## It's also possible to do a redirect here or something else as this
      ## virtual host is not needed for Matrix. It's recommended though to
      ## *not put* element here. See the NixOS manual.
      "/".extraConfig = "return 404;";

      ## Forward all Matrix API calls to the synapse Matrix homeserver. A
      ## trailing slash *must not* be used here. Forward requests for e.g. SSO
      ## and password-resets.
      "/_matrix".proxyPass = "http://[::1]:8008";
      "/_synapse/client".proxyPass = "http://[::1]:8008";
    };
  };

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = "niols.fr";
      public_baseurl = "https://matrix.niols.fr";
      listeners = [{
        port = 8008;
        bind_addresses = [ "::1" "127.0.0.1" ];
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [{
          names = [ "client" "federation" ];
          compress = false;
        }];
      }];
      signing_key_path = config.age.secrets.matrix-synapse-signing-key.path;
    };
    extraConfigFiles = [
      config.age.secrets.matrix-synapse-macaroon-secret.path
      config.age.secrets.matrix-synapse-registration-secret.path
    ];
  };

  age.secrets.matrix-synapse-macaroon-secret = {
    file = "${secrets}/matrix-synapse-macaroon-secret.age";
    owner = "matrix-synapse";
  };
  age.secrets.matrix-synapse-registration-secret = {
    file = "${secrets}/matrix-synapse-registration-secret.age";
    owner = "matrix-synapse";
  };
  age.secrets.matrix-synapse-signing-key = {
    file = "${secrets}/matrix-synapse-signing-key.age";
    owner = "matrix-synapse";
  };
}
