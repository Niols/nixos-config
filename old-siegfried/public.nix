# # =========================== [ Public files ] =========================== # #
##
## This file contains configuration related to the “public” files of Siegfried.
## They are the TV shows, movies, music, etc. that can be freely shared to most
## users and that are used by several services.

_:

{
  users.groups.public = { };

  ## The following defines a timer that ensures that everything in `/srv` always
  ## has group `public` and group permissions equal to user permissions. This
  ## allows other services to freely manipulate data in there.

  systemd.timers.make-srv-public = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*:0/5";
  };

  systemd.services.make-srv-public = {
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      chgrp -R public /srv
      chmod -R g=u /srv
    '';
  };

  ## The following defines an NFS share with Orianne for everything in `/srv`.
  ## Orianne uses this to then share it to the world with Jellyfin.

  services.nfs.server = {
    enable = true;
    exports = ''
      /srv        158.178.195.191(rw,fsid=0,no_subtree_check)
      /srv/movies 158.178.195.191(rw,nohide,insecure,no_subtree_check)
      /srv/music  158.178.195.191(rw,nohide,insecure,no_subtree_check)
      /srv/shows  158.178.195.191(rw,nohide,insecure,no_subtree_check)
    '';
    ##            ^^^ Orianne ^^^
  };
}
