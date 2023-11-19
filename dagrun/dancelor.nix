{ config, secrets, inputs', ... }:

{
  users.users.dancelor.isSystemUser = true;

  systemd.services.dancelor = {
    serviceConfig.ExecStart = "${inputs'.dancelor}/bin/dancelor --help";
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
