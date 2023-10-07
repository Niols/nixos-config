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

      "Philippe/DCIM/SD Card" = {
        path = "/hester/services/syncthing/Philippe/DCIM/SD Card";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/DCIM/Storage" = {
        path = "/hester/services/syncthing/Philippe/DCIM/Storage";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/Movies/Storage" = {
        path = "/hester/services/syncthing/Philippe/Movies/Storage";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/Pictures/SD Card" = {
        path = "/hester/services/syncthing/Philippe/Pictures/SD Card";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/Pictures/Storage" = {
        path = "/hester/services/syncthing/Philippe/Pictures/Storage";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/Scans" = {
        path = "/hester/services/syncthing/Philippe/Scans";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };
    };

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
}
