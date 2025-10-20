{ config, lib, ... }:

let
  inherit (lib) mkMerge mkIf;

in
{
  config = mkMerge [
    (mkIf config.x_niols.services.mastodon.enabledOnAnyServer {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        mastodon  IN  CNAME  ${config.x_niols.services.mastodon.enabledOn}
      '';
    })

    (mkIf config.x_niols.services.mastodon.enabledOnThisServer {
      services.mastodon = {
        enable = true;

        localDomain = "mastodon.niols.fr";
        configureNginx = true;

        ## Number of processes used by the mastodon-streaming service. Recommended
        ## is the amount of CPU cores minus one.
        streamingProcesses = 3;

        extraConfig.SINGLE_USER_MODE = "true";

        smtp = {
          fromAddress = "no-reply@niols.fr";

          host = "mail.infomaniak.com";
          port = 465;

          authenticate = true;
          user = "no-reply@niols.fr";
          passwordFile = config.age.secrets.mastodon-noreply-password.path;
        };
      };
    })
  ];
}
