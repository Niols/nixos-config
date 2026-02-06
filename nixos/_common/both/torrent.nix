{ config, lib, ... }:

let
  inherit (lib) mkMerge mkIf;

  dataDir = "/hester/services/rtorrent";

in
{
  config = mkMerge [
    (mkIf config.x_niols.services.torrent.enabledOnAnyServer {
      services.bind.x_niols.zoneEntries."niols.fr" = ''
        torrent  IN  CNAME  helga
      '';
    })

    (mkIf config.x_niols.services.torrent.enabledOnThisServer {
      services.rtorrent = {
        enable = true;

        inherit dataDir;
        downloadDir = "${dataDir}/incomplete";

        configText = ''
          pieces.sync.always_safe.set = 1

          ## Watch for .torrent in rtorrent/watch
          schedule2 = watch_watch, 10, 10, "load.start=${dataDir}/watch/*.torrent"

          ## Active view
          schedule2 = filter_active,30,30,"view.filter = active,\"or={d.up.rate=,d.down.rate=}\""

          ## Automatically move finished downloads to rtorrent/complete
          method.insert = d.get_finished_dir, simple, "cat=${dataDir}/complete/,$d.custom1="
          method.insert = d.get_data_full_path, simple, "branch=((d.is_multi_file)),((cat,(d.directory))),((cat,(d.directory),/,(d.name)))"
          method.insert = d.move_to_complete, simple, "d.directory.set=$argument.1=; execute=mkdir,-p,$argument.1=; execute=mv,-u,$argument.0=,$argument.1=; d.save_full_session="
          method.set_key = event.download.finished,move_complete,"d.move_to_complete=$d.get_data_full_path=,$d.get_finished_dir="

          ## Enable peer discovery beyond HTTP trackers
          ##
          ## - support for UDP-based trackers; they are ignored by torrents marked private anyway
          ## - Distributed Hash Table (DHT) allows finding more peers; we only enable it
          ##   when a torrent can use it, otherwise it keeps growing and using more bandwidth
          ## - Peer EXchange (PEX) allows getting peers from other peers
          ##
          trackers.use_udp.set = yes
          dht.mode.set = auto
          protocol.pex.set = yes
        '';
      };

      ## Mount Hester's /services/rtorrent, owned by `rtorrent`, but give `niols`
      ## access to it.
      _common.hester.fileSystems.services-rtorrent = {
        path = "/services/rtorrent";
        uid = config.services.rtorrent.user;
        gid = config.services.rtorrent.group;
      };
      users.groups.${config.services.rtorrent.group}.members = [ "niols" ];

      ## While we're at it, mount Hester's /medias so we can move things there.
      _common.hester.fileSystems.medias.path = "/medias";

      services.rutorrent = {
        enable = true;
        hostName = "torrent.niols.fr";
        plugins = [
          "httprpc"
          "theme"
        ];
        nginx.enable = true;
      };
      services.nginx.virtualHosts.${config.services.rutorrent.hostName} = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          basicAuthFile = config.age.secrets.rutorrent-passwd.path;
        };
      };
      age.secrets.rutorrent-passwd = {
        owner = "nginx";
        group = "nginx";
      };
    })
  ];
}
