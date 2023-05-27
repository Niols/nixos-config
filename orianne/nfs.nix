_:

{
  fileSystems."/srv/shows" = {
    device = "siegfried.niols.fr:/shows";
    fsType = "nfs";
    options = [ "x-systemd.automount=noauto" "x-systemd.idle-timeout=600" ];
  };
}
