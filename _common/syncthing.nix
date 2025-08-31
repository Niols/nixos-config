{
  config,
  lib,
  ...
}:

let
  inherit (builtins) elem mapAttrs;
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.attrsets) filterAttrs;

  makeDefaultFolderConfig =
    key: folder:
    mapAttrs (_: mkDefault) (
      folder
      // {
        path = "${config.services.syncthing.x_niols.defaultFolderPrefix}/${key}";
      }
      // config.services.syncthing.x_niols.extraDefaultFolderConfig
    );

  devicesContainsThisDevice =
    _: folder: elem config.services.syncthing.x_niols.thisDevice folder.devices;

  makeSyncthingFolders =
    folders: mapAttrs makeDefaultFolderConfig (filterAttrs devicesContainsThisDevice folders);

in
{
  options.services.syncthing.x_niols = {
    enableCommonFoldersAndDevices = mkEnableOption { };
    defaultFolderPrefix = mkOption { };
    extraDefaultFolderConfig = mkOption { default = { }; };
    thisDevice = mkOption { };
  };

  config = mkIf config.services.syncthing.x_niols.enableCommonFoldersAndDevices {
    services.syncthing = {
      overrideFolders = true;
      settings.folders = makeSyncthingFolders {
        Organiser.devices = [
          "Barbara"
          "Oxana"
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        MobileSheets.devices = [
          "Barbara"
          "Oxana"
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        Music.devices = [
          "Barbara"
          "Philippe"
          "Phineas"
          "Siegfried"
        ];

        "Oxana/Documents".devices = [
          "Oxana"
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Oxana/Notes".devices = [
          "Oxana"
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Philippe/DCIM/SD Card".devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Philippe/DCIM/Storage".devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Philippe/Movies/Storage".devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Philippe/Pictures/SD Card".devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Philippe/Pictures/Storage".devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Philippe/Scans".devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Phineas/DCIM".devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Phineas/Documents".devices = [
          "Barbara"
          "Oxana"
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Phineas/Download".devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Phineas/Pictures".devices = [
          "Philippe"
          "Phineas"
          "Siegfried"
          "Wallace"
        ];

        "Wallace/.config/doom".devices = [
          "Siegfried"
          "Wallace"
        ];

        "Wallace/.config/i3".devices = [
          "Siegfried"
          "Wallace"
        ];
      };

      overrideDevices = true;
      settings.devices = {
        Barbara.id = "E7HZWE3-HB34JFR-DQ32B5K-NAUHD24-W7IS5RX-NDCR546-KAKWW5D-BV3Y3Q6";
        Philippe.id = "BJJ7KND-NXILKPP-WLFUWOR-E6SCV6N-WRUN7RE-TUCKN6S-HIHVEF6-EIDI5AS";
        Phineas.id = "5Y465HU-EQAATXE-ADZ5K3U-AEKXHRD-WPJJIE2-QJUC3PM-KX5SKL5-DLCE3AY";
        Oxana.id = "HYNDGWO-FQ7PP2U-EQJUFPR-FSHLZP6-DIU54FU-HBSLUZD-MJDYJFZ-TW5TOQL";
        Wallace.id = "4CGPDOY-WHAWYRZ-OIOF4RN-75UA5QO-JEUBXAA-AWFRAAR-3MTBXFM-IGM3GQG";
        Siegfried = {
          id = "HTWB4DP-OZOHWUQ-726RZSD-77S3TAF-JULJVE5-DCBVE5T-A37LY2L-GFR37AO";
          addresses = [ "tcp://siegfried.niols.fr/" ];
        };
      };
    };
  };
}
