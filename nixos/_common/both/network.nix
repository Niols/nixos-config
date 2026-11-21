{
  config,
  lib,
  machines,
  ...
}:

let
  inherit (lib)
    mapAttrsToList
    mapAttrs'
    filterAttrs
    optional
    ;

  nebulaPort = 4242;
  canBeNebulaLighthouse = meta: meta ? ipv4 || meta ? ipv6;
  isNebulaLighthouse = canBeNebulaLighthouse machines.this;
  nebulaLighthouses = filterAttrs (_: meta: canBeNebulaLighthouse meta) machines.all;

in
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

  ## Nebula mesh to link all machines together. The machines with truly
  ## static IPs serve as lighthouses. Once the mesh is established, all
  ## machines (including laptops) see each other with a “static” internal
  ## IP, which can be used for configuration and security.
  ##
  services.nebula.networks.mesh = {
    enable = true;

    listen.port = if isNebulaLighthouse then nebulaPort else 0;

    ## This machine's certificate and key and the CA certificate.
    cert = config.age.secrets."nebula-mesh-${machines.this.name}-crt".path;
    key = config.age.secrets."nebula-mesh-${machines.this.name}-key".path;
    ca = config.age.secrets."nebula-mesh-ca-crt".path;

    ## Machines can be lighthouses, or know of the lighthouses' internal IP
    ## list. All machine know of a mapping from lighthouses' internal IPs to
    ## their public IPs.
    isLighthouse = isNebulaLighthouse;
    lighthouses =
      if isNebulaLighthouse then [ ] else (mapAttrsToList (_: meta: meta.internalIp) nebulaLighthouses);
    staticHostMap = mapAttrs' (_: meta: {
      name = meta.internalIp;
      value =
        optional (meta ? ipv4) "${meta.ipv4}:${toString nebulaPort}"
        ++ optional (meta ? ipv6) "[${meta.ipv6}]:${toString nebulaPort}";
    }) nebulaLighthouses;

    ## If possible to reach a machine via `192.168.*`, prefer that over a public
    ## IP. In any case, enable NAT traversal.
    settings = {
      preferred_ranges = [ "192.168.0.0/16" ];
      punchy = {
        punch = true;
        respond = true;
      };
    };

    firewall.outbound = [
      {
        host = "any";
        port = "any";
        proto = "any";
      }
    ];
    firewall.inbound = [
      {
        host = "any";
        port = "any";
        proto = "any";
      }
    ];
  };

  age.secrets."nebula-mesh-${machines.this.name}-crt" = {
    owner = "nebula-mesh";
    group = "nebula-mesh";
  };
  age.secrets."nebula-mesh-${machines.this.name}-key" = {
    owner = "nebula-mesh";
    group = "nebula-mesh";
  };
  age.secrets."nebula-mesh-ca-crt" = {
    owner = "nebula-mesh";
    group = "nebula-mesh";
  };

  ## Machines know of each other's internal IP statically.
  networking.hosts = mapAttrs' (name: meta: {
    name = meta.internalIp;
    value = [ "${name}.internal" ];
  }) machines.all;
}
