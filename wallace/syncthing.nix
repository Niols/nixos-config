{ config, secrets, ... }:

{
  services.syncthing = {
    enable = true;
    user = "niols";
    configDir = "/home/niols/.config/syncthing/";

    key = config.age.secrets.syncthing-wallace-key.path;
    cert = config.age.secrets.syncthing-wallace-cert.path;

    overrideFolders = true;
    settings.folders = {
      Music = {
        path = "~/Music";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      Organiser = {
        path = "~/.organiser";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/DCIM/SD Card" = {
        path = "~/Philippe/DCIM/SD Card";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/DCIM/Storage" = {
        path = "~/Philippe/DCIM/Storage";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/Movies/Storage" = {
        path = "~/Philippe/Movies/Storage";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/Pictures/SD Card" = {
        path = "~/Philippe/Pictures/SD Card";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/Pictures/Storage" = {
        path = "~/Philippe/Pictures/Storage";
        devices = [ "Barbara" "Philippe" "Siegfried" ];
      };

      "Philippe/Scans" = {
        path = "~/Philippe/Scans";
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

  age.secrets.syncthing-wallace-key.file =
    "${secrets}/syncthing-wallace-key.age";
  age.secrets.syncthing-wallace-cert.file =
    "${secrets}/syncthing-wallace-cert.age";
}
