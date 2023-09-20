{ config, secrets, ... }:

{
  services.syncthing = {
    enable = true;
    user = "syncthing";

    key = config.age.secrets.syncthing-siegfried-key.path;
    cert = config.age.secrets.syncthing-siegfried-cert.path;

    guiAddress = "127.0.0.1:8384";
    settings.gui.insecureSkipHostcheck = true;

    overrideFolders = true;
    settings.folders = {
      Music = {
        path = "/hester/music";
        ignorePerms = true;
        devices = [ "Barbara" "Philippe" "Wallace" ];
      };

      Organiser = {
        path = "/hester/organiser";
        ignorePerms = true;
        devices = [ "Barbara" "Philippe" "Wallace" ];
      };
    };

    ## NOTE: `readFile` is usually very bad with secrets. However, here, we are
    ## only talking about the ids of the peers, so it is not the worst. Ideally,
    ## though, we could get the ids from a path.
    overrideDevices = true;
    settings.devices = {
      "Barbara".id =
        "E7HZWE3-HB34JFR-DQ32B5K-NAUHD24-W7IS5RX-NDCR546-KAKWW5D-BV3Y3Q6";
      "Philippe".id =
        "BJJ7KND-NXILKPP-WLFUWOR-E6SCV6N-WRUN7RE-TUCKN6S-HIHVEF6-EIDI5AS";
      "Siegfried".id =
        "HTWB4DP-OZOHWUQ-726RZSD-77S3TAF-JULJVE5-DCBVE5T-A37LY2L-GFR37AO";
      "Wallace".id =
        "4CGPDOY-WHAWYRZ-OIOF4RN-75UA5QO-JEUBXAA-AWFRAAR-3MTBXFM-IGM3GQG";
    };
  };

  users.groups.hester.members = [ "syncthing" ];

  systemd.services.syncthing-init.unitConfig.RequiresMountsFor = "/hester";
  systemd.services.syncthing.unitConfig.RequiresMountsFor = "/hester";

  services.nginx.virtualHosts.syncthing = {
    serverName = "syncthing.niols.fr";

    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8384";
      basicAuthFile = config.age.secrets.syncthing-siegfried-passwd.path;
    };
  };

  age.secrets.syncthing-siegfried-passwd = {
    file = "${secrets}/syncthing-siegfried-passwd.age";
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  age.secrets.syncthing-siegfried-key.file =
    "${secrets}/syncthing-siegfried-key.age";
  age.secrets.syncthing-siegfried-cert.file =
    "${secrets}/syncthing-siegfried-cert.age";

  ## FIXME: unused for now; one would need a way to specify paths containing ids.
  age.secrets.syncthing-barbara-id.file = "${secrets}/syncthing-barbara-id.age";
  age.secrets.syncthing-philippe-id.file =
    "${secrets}/syncthing-philippe-id.age";
  age.secrets.syncthing-wallace-id.file = "${secrets}/syncthing-wallace-id.age";
}
