{ config, secrets, dancelor, ... }:

let dancelor' = dancelor.packages.x86_64-linux.dancelor;

in {
  users.users.dancelor = {
    isSystemUser = true;
    group = "dancelor";
  };
  users.groups.dancelor = { };

  systemd.services.dancelor = {
    serviceConfig = {
      ExecStart = ''
        mkdir -p /var/cache/dancelor/{version,set,book}

        ${dancelor'}/bin/dancelor-server \
          --cache /var/cache/dancelor \
          --database /var/lib/dancelor/database \
          --loglevel info \
          --port 6872 \
          --share ${dancelor'}/share
      '';
      Restart = "always";
      User = "dancelor";
      Group = "dancelor";
    };
  };

  nix.settings = {
    substituters = [ "https://dancelor.cachix.org" ];
    trusted-public-keys =
      [ "dancelor.cachix.org-1:Q2pAI0MA6jIccQQeT8JEsY+Wfwb/751zmoUHddZmDyY=" ];
  };

  age.secrets.dancelor-passwd = {
    file = "${secrets}/dancelor-passwd.age";
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  services.nginx.virtualHosts.dancelor = {
    serverName = "new.dancelor.org";

    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:6872";
      basicAuthFile = config.age.secrets.dancelor-passwd.path;
    };
  };
}
