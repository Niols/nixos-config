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
          "Ahlaya"
          "Barbara"
          "Camille"
          "Oxana"
          "Phineas"
          "Server"
          "Gromit"
        ];

        MobileSheets.devices = [
          "Ahlaya"
          "Barbara"
          "Camille"
          "Oxana"
          "Phineas"
          "Server"
          "Gromit"
        ];

        Music.devices = [
          "Barbara"
          "Phineas"
          "Server"
        ];

        Scottish-ish.devices = [
          "Barbara"
          "Phineas"
          "Server"
        ];

        "Boox/Documents".devices = [
          "Ahlaya"
          "Camille"
          "Oxana"
          "Phineas"
          "Server"
          "Gromit"
        ];

        "Boox/Notes".devices = [
          "Ahlaya"
          "Camille"
          "Oxana"
          "Phineas"
          "Server"
          "Gromit"
        ];

        "Phineas/DCIM".devices = [
          "Ahlaya"
          "Phineas"
          "Server"
          "Gromit"
        ];

        "Phineas/Documents".devices = [
          "Ahlaya"
          "Barbara"
          "Camille"
          "Oxana"
          "Phineas"
          "Server"
          "Gromit"
        ];

        "Phineas/Download".devices = [
          "Ahlaya"
          "Phineas"
          "Server"
          "Gromit"
        ];

        "Phineas/Pictures".devices = [
          "Ahlaya"
          "Phineas"
          "Server"
          "Gromit"
        ];
      };

      overrideDevices = true;
      settings.devices = {
        Barbara.id = "E7HZWE3-HB34JFR-DQ32B5K-NAUHD24-W7IS5RX-NDCR546-KAKWW5D-BV3Y3Q6";
        Camille.id = "IHKVBZ6-H5VAFJ2-KIQPURT-JQBGLHH-YLEKPBN-SB2WHUJ-5KZHNKP-6WPKOQR";
        Phineas.id = "5Y465HU-EQAATXE-ADZ5K3U-AEKXHRD-WPJJIE2-QJUC3PM-KX5SKL5-DLCE3AY";
        Oxana.id = "HYNDGWO-FQ7PP2U-EQJUFPR-FSHLZP6-DIU54FU-HBSLUZD-MJDYJFZ-TW5TOQL";
        Ahlaya.id = "SGAFF5O-IMVLLWM-G5JG6R3-Y6HWZBH-I4R7NPO-5YK3HL3-CABWEYB-IB27KAB";
        Gromit.id = "TKMS33R-MUJALFM-DOXFCQO-NS7UWJ2-FHW4EBE-EJMZZGZ-HSM3EO7-JAQEHQ5";
        Server.id = "HTWB4DP-OZOHWUQ-726RZSD-77S3TAF-JULJVE5-DCBVE5T-A37LY2L-GFR37AO";
      };
    };
  };
}
