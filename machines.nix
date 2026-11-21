let
  inherit (builtins)
    mapAttrs
    listToAttrs
    filter
    attrNames
    ;

  filterAttrs =
    f: x:
    listToAttrs (
      filter ({ name, value }: f name value) (
        map (name: {
          inherit name;
          value = x.${name};
        }) (attrNames x)
      )
    );

  ## The prefix of the IPs used for the internal WireGuard network. It can be
  ## anything within 10.x but we choose something fairly unique in the hope of
  ## avoiding conflicts with other networks.
  ##
  internalIpPrefix = "10.187.94.";
  internalPrefixLength = 24;

  ## Some metadata for the machines of this configuration. Machines
  ## can have a bunch of different IPs:
  ##
  ## - public IPs (fields `ipv4` and `ipv6`) are static IPs on the
  ##   public network, eg. IPs given for a VM by a cloud provider
  ##
  ## - “local” IPs are IPs on the local network, for instance in a
  ##   home 192.168.* network, or internally to a cloud provider
  ##
  ## - “internal” IPs are IPs in the WireGuard network that binds all
  ##   machines together; it is derived from `internalIpPrefix` and the
  ##   internal index of each machine.

  makeAll = mapAttrs (
    name: meta:
    meta
    // {
      inherit name;
      internalIp = "${internalIpPrefix}${toString meta.internalIndex}";
      internalIpCidr = "${internalIpPrefix}${toString meta.internalIndex}/${toString internalPrefixLength}";
    }
  );

  all = makeAll {
    ahlaya = {
      kind = "laptop";
      internalIndex = 4;
    };

    anastasia = {
      kind = "server";
      localIp = "192.168.1.11";
      localIpCidr = "192.168.1.11/24";
      internalIndex = 1;
      cores = 2;
    };

    gromit = {
      kind = "laptop";
      internalIndex = 5;
    };

    helga = {
      kind = "server";
      ipv4 = "188.245.212.11";
      ipv6 = "2a01:4f8:1c1c:42dc::1"; # in fact, we have the whole /64 subnet
      internalIndex = 2;
      cores = 2;
    };

    orianne = {
      kind = "server";
      ipv4 = "89.168.38.231";
      internalIndex = 3;
      cores = 2;
    };
  };

in
{
  inherit all;
  laptops = filterAttrs (_: { kind, ... }: kind == "laptop") all;
  servers = filterAttrs (_: { kind, ... }: kind == "server") all;
}
