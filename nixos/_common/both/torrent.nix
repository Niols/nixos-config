{ config, lib, ... }:

let
  inherit (lib) mkMerge mkIf;

  dataDir = "/data/services/torrent/rtorrent";

in
{
  config = mkMerge [
    (mkIf config.x_niols.services.torrent.enabledOnAnyServer {
      x_niols.dnsZoneEntries."niols.fr"."torrent" = {
        type = "CNAME";
        value = "${config.x_niols.services.torrent.enabledOn}.niols.fr.";
      };
    })

    (mkIf config.x_niols.services.torrent.enabledOnThisServer {
      services.rtorrent = {
        enable = true;

        inherit dataDir;
        downloadDir = "${dataDir}/incomplete";

        configText = ''
          pieces.sync.always_safe.set = 1

          ## Watch for .torrent in rtorrent/watch
          schedule = watch_watch, 10, 10, "load.start=${dataDir}/watch/*.torrent"

          ## Active view
          schedule = filter_active,30,30,"view.filter = active,\"or={d.up.rate=,d.down.rate=}\""

          ## Automatically move finished downloads to rtorrent/complete
          method.insert = d.get_finished_dir, simple, "cat=${dataDir}/complete/,$d.custom1="
          method.insert = d.get_data_full_path, simple, "branch=((d.is_multi_file)),((cat,(d.directory))),((cat,(d.directory),/,(d.name)))"
          method.insert = d.move_to_complete, simple, "d.directory.set=$argument.1=; execute=mkdir,-p,$argument.1=; execute=mv,-u,$argument.0=,$argument.1=; d.save_full_session="
          method.set_key = event.download.finished,move_complete,"d.move_to_complete=$d.get_data_full_path=,$d.get_finished_dir="

          ## Enable UDP trackers; ignored by torrents marked private anyway
          trackers.use_udp.set = yes

          ## Disable DHT and PEX (NixOS module's default)
          ##
          ## - Distributed Hash Table (DHT) allows finding more peers
          ## - Peer EXchange (PEX) allows getting peers from other peers
          ##
          ## If enabled, DHT should be on `auto`, to avoid taking too much
          ## bandwidth. However, DHT exposes us to the whole world, so better
          ## not. PEX exposes us to a full swarm (everyone downloading the same
          ## torrent) at once, which is much less but still quite a bit.
          ##
          dht.mode.set = disable
          protocol.pex.set = no

          ## Enable ratio handling, stop after 200MB or at ratio 1:1
          ##
          ratio.enable=
          ratio.min.set=10
          ratio.upload.set=200M
          ratio.max.set=100
          method.set = group.seeding.ratio.command, d.stop=
        '';
      };

      ## Make sure Anastasia is automounted before starting rtorrent.
      ##
      systemd.services.rtorrent.unitConfig = {
        Requires = [ "data-services-torrent.automount" ];
        After = [ "data-services-torrent.automount" ];
      };

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
