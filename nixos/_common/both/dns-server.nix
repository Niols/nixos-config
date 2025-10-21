{
  config,
  lib,
  pkgs,
  machines,
  inputs,
  ...
}:

let
  inherit (lib)
    mkIf
    concatMapStringsSep
    head
    attrNames
    optionalString
    mkOption
    types
    genAttrs
    ;
  inherit (pkgs)
    writeText
    runCommandNoCC
    ;

  forConcatAttrs = set: f: concatMapStringsSep "\n" (name: f name set.${name}) (attrNames set);

  ## Write a DNS zone file to the store and return its path. We check the file
  ## with BIND's `named-checkzone` utility.
  ##
  writeZoneFile =
    domain: content:
    let
      unchecked = writeText "${domain}.zone-unchecked" content;
    in
    runCommandNoCC "${domain}.zone" { buildInputs = [ pkgs.bind ]; } ''
      named-checkzone ${domain} ${unchecked} && cp ${unchecked} $out
    '';

  domains = [
    "niols.fr"
    "jeannerod.fr"
    "dancelor.org"
  ];

in
{
  options.services.bind.x_niols.zoneEntries = genAttrs domains (
    domain:
    mkOption {
      description = "Zone entries for domain ${domain}.";
      example = ''
        call      IN  CNAME  helga
        mastodon  IN  CNAME  siegfried
      '';
      type = types.lines;
    }
  );

  ## All our servers are also DNS servers for the whole zone.
  config = mkIf config.x_niols.isServer {
    services.bind = {
      enable = true;

      x_niols.zoneEntries = {
        "niols.fr" = ''
          ${forConcatAttrs machines.servers (
            name: meta: optionalString (meta ? ipv4) "${name}  IN  A     ${meta.ipv4}"
          )}
          ${forConcatAttrs machines.servers (
            name: meta: optionalString (meta ? ipv6) "${name}  IN  AAAA  ${meta.ipv6}"
          )}
          hester       IN  CNAME  u363090.your-storagebox.de.
          scd          IN  CNAME  niols.github.io.
          dev.scd      IN  CNAME  niols.github.io.
          @            IN  TXT    "google-site-verification=ovBb3XY6sqMtNUBFMk7vEcfrvTCgeOZujBwJ2RoTTcQ"
          _dmarc       IN  TXT    "v=DMARC1; p=none; rua=mailto:admin@niols.fr; ruf=mailto:admin@niols.fr; fo=1; pct=100; adkim=s; aspf=s"
        '';
      };

      ## All the zones contain some common definitions, in particular the SOA and
      ## the `*.niols.fr` NS servers. NOTE: It is therefore normal to have hardcoded
      ## `niols.fr` in this part instead of `${domain}`.
      ##
      zones = map (domain: {
        name = domain;
        master = true;
        file = writeZoneFile domain ''
          $TTL 3600

          @  IN  SOA ${head (attrNames machines.servers)}.niols.fr admin.niols.fr (
            ${toString inputs.self.lastModified} ; serial number - need to increase with every change
            3600    ; refresh - how often secondary name servers should check for zone updates
            1800    ; retry - in case of failure to contact primary, how long to wait before retrying
            604800  ; expire - in case of failure to contact primary, how long before giving up
            86400   ; negative TTL - how long to cache negative responses for
          )

          ${forConcatAttrs machines.servers (name: _: "@  IN  NS  ${name}.niols.fr.")}

          @             IN  MX 5   mta-gw.infomaniak.ch.
          @             IN  TXT    "v=spf1 include:spf.infomaniak.ch include:mx.ovh.com -all"
          autoconfig    IN  CNAME  infomaniak.com.
          autodiscover  IN  CNAME  infomaniak.com.
          _domainkey    IN  NS     ns41.infomaniak.com.
          _domainkey    IN  NS     ns42.infomaniak.com.

          ${config.services.bind.x_niols.zoneEntries.${domain}}
        '';
      }) domains;

      ## Only localhost can use BIND as a recursive resolver. For the rest of
      ## the world, we are only an authoritative server.
      ##
      ## NOTE: We could add `recursion no` to `extraOptions`, which would
      ## prevent other machines to query DNS servers through us, mitigating DNS
      ## amplification attacks. Since we are an authoritative server for our own
      ## zones, this would be a good behaviour. However, that would mean having
      ## to rely on external DNS servers (Google, Cloudflare, etc.) for all
      ## resolutions, including in our own zones, which feels wrong.
      ##
      cacheNetworks = [
        "127.0.0.0/8"
        "::1/128"
      ];

      ## `notify no`: do not notify other `NS` servers of zone changes. They don't
      ## need it because they are just as authoritative as we are and they get the
      ## zone through our NixOS deployment.
      ##
      ## `rate-limit`: self-explanatory; but we do not rate-limit localhost,
      ## since such services will rely on BIND for DNS resolution.
      ##
      extraOptions = ''
        notify no;
        rate-limit {
          responses-per-second 10;
          exempt-clients { 127.0.0.0/8; ::1/128; };
        };
      '';
    };

    networking = {
      ## Open Firewall ports for BIND to behave as authoritative server for our
      ## zones.
      firewall.allowedTCPPorts = [ 53 ];
      firewall.allowedUDPPorts = [ 53 ];

      ## Use localhost as DNS resolver, which now works because we set up BIND
      ## accordingly.
      resolvconf.useLocalResolver = true;

      ## Ignore the `resolv.conf` configuration obtained by DHCP, which may
      ## point to another server than localhost for DNS.
      dhcpcd.extraConfig = "nohook resolv.conf";
    };
  };
}
