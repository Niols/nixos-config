{ config, lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) types;
  inherit (lib.attrsets) concatMapAttrs;
  inherit (lib.lists) optionals;

  fileSystemOpt = {
    options = {
      path = mkOption { type = types.str; };
      uid = mkOption {
        type = types.str;
        default = "root";
      };
      gid = mkOption {
        type = types.str;
        default = "hester";
      };
      worldReadable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  mkHesterFileSystem =
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
{
  options = {
    _common.hester = {
      fileSystems = mkOption {
        type = types.attrsOf (types.submodule fileSystemOpt);
        default = { };
      };
    };
  };

  config = {
    fileSystems = concatMapAttrs (name: fs: {
      "hester-${name}" = mkHesterFileSystem fs;
    }) config._common.hester.fileSystems;

    users.groups.hester.members = optionals config.x_niols.enableNiolsUser [ "niols" ];
  };
}
