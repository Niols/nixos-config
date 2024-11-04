{ config, secrets, ... }:

let
  hester =
    {
      path,
      uid,
      gid,
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
        "dir_mode=0770"
        "file_mode=0660"

        ## Symbolic link support on a CIFS share.
        "mfsymlinks"
      ];
    };

in
{
  fileSystems = {
    hester-medias = hester {
      path = "/medias";
      uid = "root";
      gid = "hester";
    };
    hester-nextcloud = hester {
      path = "/services/nextcloud";
      uid = "nextcloud";
      gid = "nextcloud";
    };
  };

  users.groups.hester.members = [ "niols" ];

  age.secrets.hester-samba-credentials.file = "${secrets}/hester-samba-credentials.age";
}
