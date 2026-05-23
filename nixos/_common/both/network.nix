{
  config,
  lib,
  machines,
  ...
}:

let
  inherit (lib)
    mkMerge
    mkIf
    mapAttrsToList
    ;

  wgListenPort = 51821;

in
{
  config = mkMerge [
    {
      networking = {
        hostName = config.x_niols.thisMachinesName;
        domain = "niols.fr";

        nameservers = [
          "1.1.1.1"
          "1.0.0.1" # Cloudflare
          "8.8.8.8"
          "8.8.4.4" # Google
        ];
      };
    }

    ## Server machines share a common WireGuard configuration, which allows them
    ## to communicate securely over the Internet and to have static IPs.
    ##
    (mkIf config.x_niols.isServer {
      networking.wireguard.interfaces.niols = {
        ips = [ "${machines.this.internalIp}/24" ];
        privateKeyFile = config.age.secrets."wireguard-${config.x_niols.thisMachinesName}-niols-key".path;
        listenPort = wgListenPort;
        peers = mapAttrsToList (name: meta: {
          inherit name;
          publicKey = meta.wgPublicKey;
          allowedIPs = [ "${meta.internalIp}/32" ];
          endpoint = mkIf (meta ? ipv4 || meta ? ipv6) "${meta.ipv4 or meta.ipv6}:${toString wgListenPort}";
          persistentKeepalive = 25;
        }) machines.otherServers;
      };
      networking.firewall.allowedUDPPorts = [ wgListenPort ];
    })
  ];
}
