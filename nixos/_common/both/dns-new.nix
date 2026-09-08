{
  config,
  lib,
  pkgs,
  machines,
  ...
}:

let
  inherit (lib)
    attrNames
    filterAttrs
    mkIf
    mkMerge
    optional
    mkOption
    genAttrs
    mapAttrs
    listToAttrs
    replaceStrings
    types
    groupBy
    optionalAttrs
    length
    head
    toJSON
    filter
    concatMap
    mapAttrsToList
    genAttrs'
    elem
    ;
  inherit (pkgs)
    runCommand
    octodns
    linkFarm
    ;
  inherit (pkgs.writers)
    writeJSON
    ;

  ## Returns the single element of a list, null if empty, or throws if the
  ## list has more than one distinct element. `context` is used in the
  ## error message to help pinpoint what went wrong.
  assertSingleton =
    context: list:
    let
      distinct = lib.unique list;
    in
    if distinct == [ ] then
      null
    else if length distinct == 1 then
      head distinct
    else
      throw "${context}: expected at most one distinct value, got ${toJSON distinct}";

  ## octoDNS allows a list of type+value for a given record name; however, it
  ## does not support the list containing twice the same type; those should instead
  ## be merged into one type with several values.
  mergeSameTypeRecords =
    name: records:
    mapAttrsToList (
      type: rs:
      let
        context = "record `${name}` (type ${type})";
        singleValueTypes = [
          ## NOTE: CnameRecord (and others) inherits ValueMixin (singular)
          ## and therefore requires a .value field, not .values.
          ## https://github.com/octodns/octodns/blob/main/octodns/record/cname.py
          "CNAME"
          "ALIAS"
          "DNAME"
        ];
        values = concatMap (
          r:
          if r ? values then
            r.values
          else if r ? value then
            [ r.value ]
          else
            throw "${context}: does not contain either .value or .values"
        ) rs;
        ttl = assertSingleton context (filter (t: t != null) (map (r: r.ttl or null) rs));
      in
      {
        inherit type;
      }
      // (
        if elem type singleValueTypes then
          { value = assertSingleton context values; }
        else
          { inherit values; }
      )
      // optionalAttrs (ttl != null) { inherit ttl; }
    ) (groupBy (r: r.type) records);

  domains = [
    "niols.fr"
    "jeannerod.fr"
    "dancelor.org"
  ];

  octodnsPkg = octodns.withProviders (_ps: [ pkgs.octodns-providers.cloudflare ]); # sic

  octodnsZoneFiles = linkFarm "octodns-zones" (
    map (domain: {
      name = "${domain}.yaml";
      path = writeJSON "${domain}.yaml" (
        mapAttrs mergeSameTypeRecords config.x_niols.dnsZoneEntries.${domain}
      );
    }) domains
  );

  octodnsConfigUnchecked = writeJSON "octodns-config-unchecked.yaml" {
    processors = genAttrs' domains (domain: {
      name = "ignores-${domain}";
      value = {
        class = "octodns.processor.filter.NameRejectlistFilter";
        rejectlist = config.x_niols.dnsZoneEntriesIgnore.${domain};
      };
    });
    providers = {
      config = {
        class = "octodns.provider.yaml.YamlProvider";
        directory = "${octodnsZoneFiles}";
        default_ttl = 3600;
      };
      cloudflare = {
        class = "octodns_cloudflare.CloudflareProvider";
        token = "env/CLOUDFLARE_TOKEN";
        pagerules = false; # no URLFWD records and unsupported by CF's _account_ API tokens
      };
    };
    zones = listToAttrs (
      map (domain: {
        name = "${domain}.";
        value = {
          sources = [ "config" ];
          targets = [ "cloudflare" ];
          processors = [ "ignores-${domain}" ];
        };
      }) domains
    );
  };

  octodnsConfig =
    runCommand "octodns-config.yaml"
      {
        nativeBuildInputs = [ octodnsPkg ];
        CLOUDFLARE_TOKEN = "DUMMY";
      }
      ''
        octodns-validate --config-file=${octodnsConfigUnchecked}
        cp ${octodnsConfigUnchecked} $out
      '';

in
{
  options.x_niols.dnsZoneEntries = genAttrs domains (
    domain:
    mkOption {
      description = "Zone entries for domain ${domain}.";
      example = {
        call = {
          type = "CNAME";
          value = "helga";
        };
        mastodon = {
          type = "CNAME";
          value = "siegfried";
        };
      };
      type =
        with types;
        let
          ## An octoDNS entry is a list of records but can also be a record
          ## directly as a shortcut, which is coerced to a singleton.
          recordType = attrsOf (pkgs.formats.json { }).type;
          entryType = coercedTo recordType (r: [ r ]) (listOf recordType);
        in
        attrsOf entryType;
    }
  );

  options.x_niols.dnsZoneEntriesIgnore = genAttrs domains (
    domain:
    mkOption {
      description = "Entries to ignore for domain ${domain}, typically because they are dynamic IPs.";
      example = [ "anastasia" ];
      type = with types; listOf str;
      default = [ ];
    }
  );

  config = mkMerge [
    {
      ## Static A / AAAA entries for each of the servers.
      x_niols.dnsZoneEntries."niols.fr" = mapAttrs (
        _: meta:
        optional (meta ? ipv4) {
          type = "A";
          value = meta.ipv4;
        }
        ++ optional (meta ? ipv6) {
          type = "AAAA";
          value = meta.ipv6;
        }
      ) machines.servers;
    }

    {
      ## Infomaniak still takes care of a bunch of things for all of our domains.
      x_niols.dnsZoneEntries = genAttrs domains (_domain: {
        "" = [
          {
            type = "MX";
            value = {
              preference = 5;
              exchange = "mta-gw.infomaniak.ch.";
            };
          }
          {
            type = "TXT";
            value = "v=spf1 include:spf.infomaniak.ch include:mx.ovh.com -all";
          }
        ];
        autoconfig = {
          type = "CNAME";
          value = "infomaniak.com.";
        };
        autodiscover = {
          type = "CNAME";
          value = "infomaniak.com.";
        };
        _domainkey = {
          type = "NS";
          values = [
            "ns41.infomaniak.com."
            "ns42.infomaniak.com."
          ];
        };
      });
    }

    {
      ## Other static entries.
      x_niols.dnsZoneEntries."niols.fr" = {
        hester = {
          type = "CNAME";
          value = "u363090.your-storagebox.de.";
        };
        scd = {
          type = "CNAME";
          value = "niols.github.io.";
        };
        "dev.scd" = {
          type = "CNAME";
          value = "niols.github.io.";
        };
        "" = {
          type = "TXT";
          value = "google-site-verification=ovBb3XY6sqMtNUBFMk7vEcfrvTCgeOZujBwJ2RoTTcQ";
        };
        _dmarc = {
          type = "TXT";
          value =
            replaceStrings [ ";" ] [ "\\;" ]
              "v=DMARC1; p=none; rua=mailto:admin@niols.fr; ruf=mailto:admin@niols.fr; fo=1; pct=100; adkim=s; aspf=s";
        };
      };
    }

    (mkIf config.x_niols.services.dns.enabledOnThisServer {
      systemd.services.octodns-sync = {
        description = "Reconcile DNS zone with Cloudflare via octoDNS";
        path = [ octodnsPkg ];
        script = ''
          octodns-sync --config-file=${octodnsConfig} --doit --force
        '';
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          EnvironmentFile = config.age.secrets.octodns-cloudflare-token.path;
        };
        requires = [ "network-online.target" ]; # fails if network isn't online
        after = [ "network-online.target" ]; # only runs after network is online
        ## NOTE: this `wantedBy` might be why the unit triggers on `nixos-rebuild`, so I removed it as of 3 June 2026
        # wantedBy = [ "network-online.target" ]; # runs when network comes online;
      };

      systemd.timers.octodns-sync = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "1h";
        };
      };
    })

    {
      x_niols.dnsZoneEntriesIgnore."niols.fr" = attrNames (
        filterAttrs (_: meta: !(meta ? ipv4 || meta ? ipv6)) machines.servers
      );
    }

    ## On servers without a static IP, we periodically check the public IP address
    ## and compare it to the one in the DNS records, and update if need be.
    ##
    ## NOTE: We also need to inform octoDNS to leave this field alone; see the
    ## 'dnsZoneEntriesIgnore' stuff above.
    ##
    ## NOTE: The 'A' / 'AAAA' records must exist for ddclient to update them. This
    ## is a one-time bootstraping process that must be done manually.
    ##
    (mkIf (config.x_niols.isServer && !(machines.this ? ipv4 || machines.this ? ipv6)) {
      services.ddclient = {
        enable = true;
        interval = "5min";
        protocol = "cloudflare";
        username = "token";
        passwordFile = config.age.secrets.ddclient-cloudflare-token.path;
        zone = "niols.fr";
        domains = [ "${machines.this.name}.niols.fr" ];
        usev6 = ""; # disable IPv6; FIXME: know whether the machine is IPv6 aware and enable if that is the case
        ssl = true;
      };
    })
  ];
}
