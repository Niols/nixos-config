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
        path = "~/.syncthing/Organiser";
        devices = [ "Barbara" "Oxana" "Philippe" "Siegfried" ];
      };

      MobileSheets = {
        path = "~/.syncthing/MobileSheets";
        devices = [ "Barbara" "Philippe" "Oxana" "Siegfried" ];
      };

      "Oxana/Documents" = {
        path = "~/.syncthing/Oxana/Documents";
        devices = [ "Oxana" "Philippe" "Siegfried" ];
      };

      "Oxana/Notes" = {
        path = "~/.syncthing/Oxana/Notes";
        devices = [ "Oxana" "Philippe" "Siegfried" ];
      };

      "Philippe/DCIM/SD Card" = {
        path = "~/.syncthing/Philippe/DCIM/SD Card";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/DCIM/Storage" = {
        path = "~/.syncthing/Philippe/DCIM/Storage";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/Movies/Storage" = {
        path = "~/.syncthing/Philippe/Movies/Storage";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/Pictures/SD Card" = {
        path = "~/.syncthing/Philippe/Pictures/SD Card";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/Pictures/Storage" = {
        path = "~/.syncthing/Philippe/Pictures/Storage";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Philippe/Scans" = {
        path = "~/.syncthing/Philippe/Scans";
        devices = [ "Philippe" "Siegfried" ];
      };

      "Wallace/.config/doom" = {
        path = "~/.config/doom";
        devices = [ "Siegfried" ];
      };

      "Wallace/.config/i3" = {
        path = "~/.config/i3";
        devices = [ "Siegfried" ];
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
