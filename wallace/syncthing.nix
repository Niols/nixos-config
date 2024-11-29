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
      Organiser = {
        path = "~/.syncthing/Organiser";
        devices = [
          "Barbara"
          "Oxana"
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      MobileSheets = {
        path = "~/.syncthing/MobileSheets";
        devices = [
          "Barbara"
          "Philippe"
          "Phineas"
          "Oxana"
          "Siegfried"
        ];
      };

      "Oxana/Documents" = {
        path = "~/.syncthing/Oxana/Documents";
        devices = [
          "Oxana"
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Oxana/Notes" = {
        path = "~/.syncthing/Oxana/Notes";
        devices = [
          "Oxana"
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Philippe/DCIM/SD Card" = {
        path = "~/.syncthing/Philippe/DCIM/SD Card";
        devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Philippe/DCIM/Storage" = {
        path = "~/.syncthing/Philippe/DCIM/Storage";
        devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Philippe/Movies/Storage" = {
        path = "~/.syncthing/Philippe/Movies/Storage";
        devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Philippe/Pictures/SD Card" = {
        path = "~/.syncthing/Philippe/Pictures/SD Card";
        devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Philippe/Pictures/Storage" = {
        path = "~/.syncthing/Philippe/Pictures/Storage";
        devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Philippe/Scans" = {
        path = "~/.syncthing/Philippe/Scans";
        devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Phineas/DCIM" = {
        path = "~/.syncthing/Phineas/DCIM";
        devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Phineas/Documents" = {
        path = "~/.syncthing/Phineas/Documents";
        devices = [
          "Barbara"
          "Oxana"
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Phineas/Download" = {
        path = "~/.syncthing/Phineas/Download";
        devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
      };

      "Phineas/Pictures" = {
        path = "~/.syncthing/Phineas/Pictures";
        devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
        ];
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
      "Barbara".id = "E7HZWE3-HB34JFR-DQ32B5K-NAUHD24-W7IS5RX-NDCR546-KAKWW5D-BV3Y3Q6";
      "Philippe".id = "BJJ7KND-NXILKPP-WLFUWOR-E6SCV6N-WRUN7RE-TUCKN6S-HIHVEF6-EIDI5AS";
      "Phineas".id = "5Y465HU-EQAATXE-ADZ5K3U-AEKXHRD-WPJJIE2-QJUC3PM-KX5SKL5-DLCE3AY";
      "Oxana".id = "HYNDGWO-FQ7PP2U-EQJUFPR-FSHLZP6-DIU54FU-HBSLUZD-MJDYJFZ-TW5TOQL";
      "Wallace".id = "4CGPDOY-WHAWYRZ-OIOF4RN-75UA5QO-JEUBXAA-AWFRAAR-3MTBXFM-IGM3GQG";
      "Siegfried" = {
        id = "HTWB4DP-OZOHWUQ-726RZSD-77S3TAF-JULJVE5-DCBVE5T-A37LY2L-GFR37AO";
        addresses = [ "tcp://siegfried.niols.fr/" ];
      };
    };
  };

  age.secrets.syncthing-wallace-key.file = "${secrets}/syncthing-wallace-key.age";
  age.secrets.syncthing-wallace-cert.file = "${secrets}/syncthing-wallace-cert.age";
}
