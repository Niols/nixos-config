_:

{
  fileSystems."/srv/shows" = {
    device = "siegfried.niols.fr:/shows";
    fsType = "nfs";
    options = [ "x-systemd.automount=noauto" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/srv/movies" = {
    device = "siegfried.niols.fr:/movies";
    fsType = "nfs";
    options = [ "x-systemd.automount=noauto" "x-systemd.idle-timeout=600" ];
  };
}
