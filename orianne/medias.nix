_: {
  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };

  services.nginx.virtualHosts.medias = {
    serverName = "medias.niols.fr";
    forceSSL = true;
    enableACME = true;
    locations."/" = { proxyPass = "http://127.0.0.1:8096"; };
  };

  users.groups.hester.members = [ "jellyfin" ];
}
