# # =========================== [ Public files ] =========================== # #
##
## This file contains configuration related to the “public” files from
## Siegfried. They are the TV shows, movies, music, etc. that can be freely
## shared to most users and that are used by several services.

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
