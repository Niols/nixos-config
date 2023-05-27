_:

{
  fileSystems."/srv/tvshows" = {
    device = "siegfried.niols.fr:/tvshows";
    fsType = "nfs";
    options = [ "x-systemd.automount=noauto" "x-systemd.idle-timeout=600" ];
  };
}
