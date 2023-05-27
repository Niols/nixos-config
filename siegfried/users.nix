_: {
  users.users.niols = {
    isNormalUser = true;
    extraGroups = [ "public" "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEElREJN0AC7lbp+5X204pQ5r030IbgCllsIxyU3iiKY niols@wallace"
    ];
  };

  users.groups.public = { };

  ## The following defines a timer that ensures that everything in `/srv` always
  ## has group `public` and group permissions equal to user permissions. This
  ## allows other services to freely manipulate data in there.

  ## NOTE: We should probably have a common file for everything that Siegfried
  ## serves, which would define the NFS but also this timer.

  systemd.timers."make-public" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
      Unit = "make-public.service";
    };
  };

  systemd.services."make-public" = {
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      chgrp -R public /srv
      chmod -R g=u /srv
    '';
  };
}
