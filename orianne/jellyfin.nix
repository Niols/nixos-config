_: {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.nginx.virtualHosts.media = {
    serverName = "media.niols.fr";

    forceSSL = true;
    enableACME = true;

    locations."/" = { return = "302 https://$host/web/"; };

    locations."/" = {
      ## Proxy main Jellyfin traffic
      proxyPass = "http://127.0.0.1:8096";

      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;

        ## Disable buffering when the nginx proxy gets very resource heavy upon streaming
        proxy_buffering off;
      '';
    };

    ## Location block for /web - This is purely for aesthetics so /web/#!/ works
    ## instead of having to go to /web/index.html/#!/
    locations."/web/" = {
      ## Proxy main Jellyfin traffic
      proxyPass = "http://127.0.0.1:8096/web/index.html";

      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
      '';
    };

    locations."/socket" = {
      ## Proxy Jellyfin Websockets traffic
      proxyPass = "http://127.0.0.1:8096";

      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Protocol $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
      '';
    };
  };
}
