{
  config,
  lib,
  machines,
  inputs,
  ...
}:

let
  inherit (lib)
    mkMerge
    mkIf
    optionalString
    ;

in
{
  imports = [ inputs.dancelor.nixosModules.dancelor ];

  config = mkMerge [
    (mkIf config.x_niols.services.dancelor.enabledOnAnyServer (
      let
        dancelorServer = machines.servers.${config.x_niols.services.dancelor.enabledOn};
      in
      {
        services.bind.x_niols.zoneEntries."dancelor.org" =
          optionalString (dancelorServer ? ipv4) ''
            @    IN  A     ${dancelorServer.ipv4}
            www  IN  A     ${dancelorServer.ipv4}
          ''
          + optionalString (dancelorServer ? ipv6) ''
            @    IN  AAAA  ${dancelorServer.ipv6}
            www  IN  AAAA  ${dancelorServer.ipv6}
          '';
      }
    ))

    (mkIf config.x_niols.services.dancelor.enabledOnThisServer {
      services.dancelor = {
        enable = true;
        databaseRepositoryFile = config.age.secrets.dancelor-database-repository.path;
        listeningPort = 6872;
        githubTokenFile = config.age.secrets.dancelor-github-token.path;
        githubRepository = "github.com/paris-branch/dancelor";
        githubDatabaseRepository = "github.com/paris-branch/dancelor-database";
      };

      ## Use Dancelor's Cachix instance as a substituter. Since Dancelor's CI fill
      ## it with all the components, this should make things much faster.
      nix.settings = {
        substituters = [ "https://dancelor.cachix.org" ];
        trusted-public-keys = [ "dancelor.cachix.org-1:Q2pAI0MA6jIccQQeT8JEsY+Wfwb/751zmoUHddZmDyY=" ];
      };

      ## A secret `passwd` file containing the users' identifiers.
      age.secrets.dancelor-github-token = {
        mode = "600";
        owner = "dancelor";
        group = "dancelor";
      };

      ## Simple Nginx HTTPS proxy in front of Dancelor. Used to handle HTTP auth,
      ## but not anymore, now that it is in Dancelor directly.
      services.nginx.virtualHosts.dancelor = {
        serverName = "dancelor.org";
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.dancelor.listeningPort}";
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
    })
  ];
}
