_: {
  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };

  services.nginx.virtualHosts.media = {
    serverName = "media.niols.fr";

    forceSSL = true;
    enableACME = true;

    locations."/" = { proxyPass = "http://127.0.0.1:8096"; };
  };
}
