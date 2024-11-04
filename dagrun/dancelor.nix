{ config, secrets, ... }:

{
  services.dancelor = {
    enable = true;
    databaseRepositoryFile = config.age.secrets.dancelor-database-repository.path;
    listeningPort = 6872;
  };

  ## A secret Git repository for the database. It will be cloned by the
  ## `dancelor-init` service and used by the `dancelor` service.
  age.secrets.dancelor-database-repository = {
    file = "${secrets}/dancelor-database-repository.age";
  };

  ## Use Dancelor's Cachix instance as a substituter. Since Dancelor's CI fill
  ## it with all the components, this should make things much faster.
  nix.settings = {
    substituters = [ "https://dancelor.cachix.org" ];
    trusted-public-keys = [ "dancelor.cachix.org-1:Q2pAI0MA6jIccQQeT8JEsY+Wfwb/751zmoUHddZmDyY=" ];
  };

  ## A secret `passwd` file containing the users' identifiers.
  age.secrets.dancelor-passwd = {
    file = "${secrets}/dancelor-passwd.age";
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  ## A simple Nginx proxy in front of Dancelor. Handles HTTPS, the generation of
  ## the certificate, and the `passwd` authentication.
  services.nginx.virtualHosts.dancelor = {
    serverName = "dancelor.org";
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:6872";
      basicAuthFile = config.age.secrets.dancelor-passwd.path;
      extraConfig = ''
        ## Dancelor relies on SVGs being embedded as objects, which can trigger
        ## the `X-Frame-Options` policy. We therefore relax it a tiny bit
        ## (compared to `DENY`). We also have to include other headers otherwise
        ## they are dropped, because `add_header` replaces all parent headers.
        ## cf http://nginx.org/en/docs/http/ngx_http_headers_module.html#add_header
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
      '';
    };
  };
}
