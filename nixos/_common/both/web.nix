{
  config,
  lib,
  machines,
  ...
}:

let
  inherit (lib)
    mkMerge
    mkIf
    mkOption
    mapAttrs'
    types
    optionalString
    escape
    ;

in
{
  options.x_niols.wellKnownFiles = mkOption {
    description = ''
      A map of static file contents to serve under .well-known/ on niols.fr.
    '';
    type = with types; attrsOf str;
  };

  config = mkMerge [
    (mkIf config.x_niols.services.web.enabledOnAnyServer (
      let
        webServer = machines.servers.${config.x_niols.services.web.enabledOn};
      in
      {
        services.bind.x_niols.zoneEntries."niols.fr" =
          optionalString (webServer ? ipv4) ''
            @          IN  A      ${webServer.ipv4}
            www        IN  A      ${webServer.ipv4}
          ''
          + optionalString (webServer ? ipv6) ''
            @          IN  AAAA   ${webServer.ipv6}
            www        IN  AAAA   ${webServer.ipv6}
          '';
        services.bind.x_niols.zoneEntries."jeannerod.fr" = ''
          nicolas      IN  CNAME  www.niols.fr.
          www.nicolas  IN  CNAME  www.niols.fr.
        '';
      }
    ))

    (mkIf config.x_niols.services.web.enabledOnThisServer {
      services.nginx.virtualHosts."niols.fr" = {
        serverAliases = [ "www.niols.fr" ];
        forceSSL = true;
        enableACME = true;
        root = "/data/services/web/niols.fr";
        locations =
          ## Serve the website, but also inject well-known files, potentially
          ## from other machine configurations.
          {
            "/" = {
              index = "index.html";
              tryFiles = "$uri $uri/ =404";
            };
          }
          // (mapAttrs' (file: text: {
            name = "= /.well-known/${file}";
            value.extraConfig = ''
              default_type application/xml;
              add_header Access-Control-Allow-Origin *;
              return 200 '${escape [ "'" ] text}';
              ## Repeat headers from the server context.
              add_header Strict-Transport-Security $hsts_header;
              add_header Referrer-Policy origin-when-cross-origin;
              add_header X-Frame-Options DENY;
              add_header X-Content-Type-Options nosniff;
              add_header X-XSS-Protection "1; mode=block";
            '';
          }) config.x_niols.wellKnownFiles);
      };

      services.nginx.virtualHosts."nicolas.jeannerod.fr" = {
        serverAliases = [ "www.nicolas.jeannerod.fr" ];
        forceSSL = true;
        enableACME = true;
        root = "/data/services/web/nicolas.jeannerod.fr";
        locations."/" = {
          index = "index.html";
          tryFiles = "$uri $uri/ =404";
        };
      };

      ## FIXME: Maybe somewhere else?
      x_niols.wellKnownFiles."autoconfig/mail/config-v1.1.xml" = ''
        <?xml version="1.0"?>
        <clientConfig version="1.1">
            <emailProvider id="niols.fr">
              <domain>niols.fr</domain>
              <domain>jeannerod.fr</domain>
              <displayName>Niols Mail</displayName>
              <incomingServer type="imap">
                 <hostname>mail.infomaniak.com</hostname>
                 <port>993</port>
                 <socketType>SSL</socketType>
                 <username>%EMAILADDRESS%</username>
                 <authentication>password-cleartext</authentication>
              </incomingServer>
              <outgoingServer type="smtp">
                 <hostname>mail.infomaniak.com</hostname>
                 <port>465</port>
                 <socketType>SSL</socketType>
                 <username>%EMAILADDRESS%</username>
                 <authentication>password-cleartext</authentication>
              </outgoingServer>
            </emailProvider>
            <clientConfigUpdate url="https://www.example.com/config/mozilla.xml" />
        </clientConfig>
      '';

      ############################################################################
      ## Daily backup

      _common.hester.backupJobs.web = {
        startAt = "*-*-* 05:00:00";
        paths = [ "/data/services/web" ];
        repokeyFile = config.age.secrets.hester-web-backup-repokey.path;
        identityFile = config.age.secrets.hester-web-backup-identity.path;
      };
    })
  ];
}
