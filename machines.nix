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
  wgIpPrefix = "10.187.93";

  ## Some metadata for the machines of this configuration.
  ##
  all = mapAttrs (name: meta: meta // { inherit name; }) {
    ahlaya = {
      kind = "laptop";
    };
    anastasia = rec {
      kind = "server";
      localIp = "192.168.1.11"; # on the local network, in this case a home 192.168.* network
      internalIndex = 1;
      internalIp = "${wgIpPrefix}.${toString internalIndex}"; # on the internal WireGuard network
      wgPublicKey = "ElfanRos88bHayCTJM9qhg1XPOM/egor8ShHoOXAz1c=";
      cores = 2;
    };
    gromit = {
      kind = "laptop";
    };
    helga = rec {
      kind = "server";
      ipv4 = "188.245.212.11";
      ipv6 = "2a01:4f8:1c1c:42dc::1"; # in fact, we have the whole /64 subnet
      internalIndex = 2;
      internalIp = "${wgIpPrefix}.${toString internalIndex}";
      wgPublicKey = "bWTTesse8keIrCO8MWmXFhhHcvwmn+s+DY2nHFi+tmw=";
      cores = 2;
    };
    orianne = rec {
      kind = "server";
      ipv4 = "89.168.38.231";
      internalIndex = 3;
      internalIp = "${wgIpPrefix}.${toString internalIndex}";
      wgPublicKey = "Gu3XXcxqxQDy+N1yFZ7fbJMpJWKOBJKeF95doHmQMT0=";
      cores = 4;
    };
  };
in

{
  inherit all wgIpPrefix;
  laptops = filterAttrs (_: { kind, ... }: kind == "laptop") all;
  servers = filterAttrs (_: { kind, ... }: kind == "server") all;
}
