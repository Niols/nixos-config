{ config, secrets, ... }:

{
  fileSystems."/hester" = {
    device = "//hester.niols.fr/backup";
    fsType = "cifs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "credentials=${config.age.secrets.hester-samba-credentials.path}"
    ];
  };

  age.secrets.hester-samba-credentials = {
    file = "${secrets}/hester-samba-credentials.age";
  };
}
