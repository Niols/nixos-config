{
  services.postgresql = {
    ensureDatabases = [ "matrix-synapse" ];
    ensureUsers = [{
      name = "matrix-synapse";
      ensureDBOwnership = true;
      ensureClauses.login = true;
    }];
    ## All databases are backed up daily. See `databases.nix`.
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
}
