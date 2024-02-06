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
        devices = [ "Barbara" "Oxana" "Philippe" "Siegfried" ];
      };

      MobileSheets = {
        path = "~/.syncthing/MobileSheets";
        ignorePerms = true;
        devices = [ "Barbara" "Philippe" "Oxana" "Siegfried" ];
      };

      "Oxana/Documents" = {
        path = "~/Oxana/Documents";
        devices = [ "Oxana" "Philippe" "Siegfried" ];
      };

      "Oxana/Notes" = {
        path = "~/Oxana/Notes";
        devices = [ "Oxana" "Philippe" "Siegfried" ];
      };

      "Philippe/DCIM/SD Card" = {
        path = "~/Philippe/DCIM/SD Card";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/DCIM/Storage" = {
        path = "~/Philippe/DCIM/Storage";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/Movies/Storage" = {
        path = "~/Philippe/Movies/Storage";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/Pictures/SD Card" = {
        path = "~/Philippe/Pictures/SD Card";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/Pictures/Storage" = {
        path = "~/Philippe/Pictures/Storage";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/Scans" = {
        path = "~/Philippe/Scans";
        devices = [ "Philippe" "Siegfried" ];
      };
    };

    overrideDevices = true;
    settings.devices = {
      "Barbara".id =
        "E7HZWE3-HB34JFR-DQ32B5K-NAUHD24-W7IS5RX-NDCR546-KAKWW5D-BV3Y3Q6";
      "Philippe".id =
        "BJJ7KND-NXILKPP-WLFUWOR-E6SCV6N-WRUN7RE-TUCKN6S-HIHVEF6-EIDI5AS";
      "Oxana".id =
        "HYNDGWO-FQ7PP2U-EQJUFPR-FSHLZP6-DIU54FU-HBSLUZD-MJDYJFZ-TW5TOQL";
      "Wallace".id =
        "4CGPDOY-WHAWYRZ-OIOF4RN-75UA5QO-JEUBXAA-AWFRAAR-3MTBXFM-IGM3GQG";
      "Siegfried" = {
        id = "HTWB4DP-OZOHWUQ-726RZSD-77S3TAF-JULJVE5-DCBVE5T-A37LY2L-GFR37AO";
        addresses = [ "tcp://siegfried.niols.fr/" ];
      };
    };
  };

  age.secrets.syncthing-wallace-key.file =
    "${secrets}/syncthing-wallace-key.age";
  age.secrets.syncthing-wallace-cert.file =
    "${secrets}/syncthing-wallace-cert.age";
}
