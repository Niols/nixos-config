{ config, secrets, ...}: {
  users.users.dancelor = {
    isNormalUser = true;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEElREJN0AC7lbp+5X204pQ5r030IbgCllsIxyU3iiKY niols@wallace"
    ];
  };

  age.secrets.dancelor-passwd = {
    file = "${secrets}/dancelor-passwd.age";
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  services.nginx.virtualHosts.dancelor = {
    serverName = "new.dancelor.org";
    serverAliases = [ "dancelor.org" "www.dancelor.org" ];

    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:6872";
      basicAuthFile = config.age.secrets.dancelor-passwd.path;
    };
  };
}
