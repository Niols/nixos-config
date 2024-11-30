{
  config,
  secrets,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkOption;
  inherit (lib.types.types)
    attrsOf
    bool
    str
    submodule
    ;
  inherit (lib.attrsets) concatMapAttrs;
in

{
  options.fileSystems.x_niols = {
    hesterMounts = mkOption {
      type = attrsOf (submodule {
        options = {
          path = mkOption { type = str; };
          uid = mkOption {
            type = str;
            default = "root";
          };
          gid = mkOption {
            type = str;
            default = "hester";
          };
          worldReadable = mkOption {
            type = bool;
            default = false;
          };
        };
      });
      default = { };
    };
  };

  config = mkIf (config.fileSystems.x_niols.hesterMounts != { }) {
    fileSystems =
      let
        mkHesterMount =
          {
            path,
            uid,
            gid,
            worldReadable,
          }:
          {
            mountPoint = "/hester" + path;
            device = "//hester.niols.fr/backup" + path;
            fsType = "cifs";
            options = [
              "_netdev"
              "x-systemd.automount"
              "noauto"
              "x-systemd.idle-timeout=60"
              "x-systemd.device-timeout=5s"
              "x-systemd.mount-timeout=5s"
              "credentials=${config.age.secrets.hester-samba-credentials.path}"
              "uid=${uid}"
              "gid=${gid}"
              "dir_mode=${if worldReadable then "0775" else "0770"}"
              "file_mode=${if worldReadable then "0664" else "0660"}"

              ## Symbolic link support on a CIFS share.
              "mfsymlinks"
            ];
          };
      in
      concatMapAttrs (name: fs: {
        "hester-${name}" = mkHesterMount fs;
      }) config.fileSystems.x_niols.hesterMounts;

    users.groups.hester.members = [ "niols" ];

    age.secrets.hester-samba-credentials.file = "${secrets}/hester-samba-credentials.age";
  };
}
