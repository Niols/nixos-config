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
      ExecStart = "${dancelor'}/bin/dancelor --help";
      Restart = "always";
      User = "dancelor";
      Group = "dancelor";
    };
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
