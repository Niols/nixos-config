{ lib, ... }:

let
  ## A static map of user ids such that they are consistent across all machines.
  ## This is in particular so that they play well with NFS and can migrate from
  ## one machine to another more easily.
  ##
  ## NOTE: By convention, all these ids should be in the range 2000-2999, to
  ## avoid clashing with root (0), statically allocated system users (1-399),
  ## dynamically allocated users (400-999) and human users (1000+).
  ##
  ## See statically alocated map of users in nixpkgs:
  ## https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix
  ##
  ## NOTE: We transitioned from automatically allocated users in the 400-999
  ## range to statically allocated users in the following map on 24 May 2026.
  ## As of this date, we are keeping a note with the old uids/gids as a
  ## comment. Eventually, we should just remove these comments.

  uids = {
    ## set in nixpkgs, duplicated here
    postgres = 71;
    mysql = 84;
    grafana = 196;
    syncthing = 237;
    mosquitto = 246;
    prometheus = 255;
    telegraf = 256;

    ## set in these configurations
    nextcloud = 2000; # was 993 on Orianne
    dancelor = 2001; # was 989 on Orianne
    jellyfin = 2002; # was 994 on Orianne
    atticd = 2003; # was automated on Helga
    rtorrent = 2004; # was 993 on Helga
    rutorrent = 2005; # was 992 on Helga
    galene = 2006; # was 990 on Helga
    mastodon = 2007; # was 992 on Siegfried
    vsftpd = 2008; # was 990 on Siegfried
    # ftp-nginx = 2009; # no user, but a group
  };

  normalUids = {
    niols = 1000;
    work = 1001;
    kerl = 1010; # was 1001 on Siegfried
  };

  gids = {
    ## set in nixpkgs, duplicated here
    postgres = 71;
    mysql = 84;
    users = 100;
    matrix-synapse = 224;
    syncthing = 237;
    mosquitto = 246;
    prometheus = 255;

    ## not set in nixpkgs but in the 1-399 range to match the user ids
    grafana = 196; # was 984 then 2003 on Orianne
    telegraf = 256; # was 981 then 2010 on Orianne

    ## set in these configurations
    nextcloud = 2000; # was 991 on Orianne
    dancelor = 2001; # was 986 on Orianne
    jellyfin = 2002; # was 992 on Orianne
    atticd = 2003; # was automated on Orianne
    rtorrent = 2004; # was 990 on Helga
    rutorrent = 2005; # was 989 on Helga
    galene = 2006; # was 987 on Helga
    mastodon = 2007; # was 991 on Siegfried
    vsftpd = 2008; # was 989 on Siegfried
    ftp-nginx = 2009; # was 988 on Siegfried
  };

  inherit (lib) mapAttrs;

in
{
  users.users =
    mapAttrs (name: uid: {
      inherit uid;
      isSystemUser = true;
      group = name;
    }) uids
    // mapAttrs (_: uid: {
      inherit uid;
      isNormalUser = true;
    }) normalUids;
  users.groups = mapAttrs (_: gid: { inherit gid; }) gids;
}
