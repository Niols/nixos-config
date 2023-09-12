_: {
  services.jellyfin = {
    enable = true;
    openFirewall = true; # # FIXME: `false` once tests are good
  };

  services.nginx.virtualHosts.media = {
    serverName = "media.niols.fr";

    forceSSL = true;
    enableACME = true;

    locations."/" = { proxyPass = "http://127.0.0.1:8096"; };
  };
}