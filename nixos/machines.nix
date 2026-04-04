let
  inherit (builtins)
    attrNames
    filter
    listToAttrs
    map
    mapAttrs
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

  all = mapAttrs (name: meta: meta // { inherit name; }) {
    ahlaya = {
      kind = "laptop";
    };
    gromit = {
      kind = "laptop";
    };
    helga = {
      kind = "server";
      ipv4 = "188.245.212.11";
      ipv6 = "2a01:4f8:1c1c:42dc::1"; # in fact, we have the whole /64 subnet
      cores = 2;
    };
    orianne = {
      kind = "server";
      ipv4 = "89.168.38.231";
      cores = 4;
    };
    siegfried = {
      kind = "server";
      ipv4 = "158.178.201.160";
      cores = 2;
    };
  };

in
{
  inherit all;
  laptops = filterAttrs (_: { kind, ... }: kind == "laptop") all;
  servers = filterAttrs (_: { kind, ... }: kind == "server") all;
}
