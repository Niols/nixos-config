{
  config,
  lib,
  pkgs,
  machines,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    optional
    mkOption
    genAttrs
    mapAttrs
    listToAttrs
    replaceStrings
    types
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
    else if builtins.length distinct == 1 then
      builtins.head distinct
    else
      throw "${context}: expected at most one distinct value, got ${builtins.toJSON distinct}";

  mergeSameTypeRecords =
    name: records:
    let
      grouped = lib.groupBy (r: r.type) records;
    in
    lib.mapAttrsToList (
      type: rs:
      if builtins.length rs == 1 then
        builtins.head rs
      else
        let
          values = builtins.concatMap (
            r:
            if r ? values then
              r.values
            else if r ? value then
              [ r.value ]
            else
              [
                (builtins.removeAttrs r [
                  "type"
                  "ttl"
                ])
              ]
          ) rs;
          ttl = assertSingleton "record ${name} (type ${type})" (
            builtins.filter (t: t != null) (map (r: r.ttl or null) rs)
          );
        in
        { inherit type values; } // lib.optionalAttrs (ttl != null) { inherit ttl; }
    ) grouped;

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
    processors.no-dynamic = {
      class = "octodns.processor.filter.NameRejectlistFilter";
      rejectlist = [ "anastasia" ];
    };
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
          processors = [ "no-dynamic" ];
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
            preference = 5;
            exchange = "mta-gw.infomaniak.ch.";
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
          set -euo pipefail
          octodns-sync --config-file=${octodnsConfig} --doit --force
        '';
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          EnvironmentFile = config.age.secrets.octodns-cloudflare-token.path;
        };
      };

      systemd.timers.octodns-sync = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "1h";
        };
      };
    })

    ## On Anastasia, which sits behind a NAT with dynamic IP, we periodically
    ## check the public IP address and compare it to the one in the DNS records
    ## of our servers. If they differ, we update the DNS records with NSUPDATE.
    ##
    # (mkIf (config.x_niols.thisMachinesName == "anastasia") {
    #   systemd.services.update-dns-with-public-ip = {
    #     script = ''
    #       echo "Getting current IP..." >&2
    #       if current_ip=$(${pkgs.dnsutils}/bin/dig -4 +short myip.opendns.com @resolver1.opendns.com); then
    #         if [ -n "$current_ip" ]; then
    #           echo "Done getting current IP; got $current_ip." >&2
    #         else
    #           echo "Failed getting current IP; got the empty string." >&2
    #           exit 1
    #         fi
    #       else
    #         echo "Failed getting current IP; dig exited with error code $?." >&2
    #         exit 1
    #       fi

    #       failure=false
    #       ${forConcat (attrNames machines.servers) (
    #         server:
    #         optionalString (server != "anastasia") ''
    #           echo "Checking DNS record on ${server}..." >&2
    #           if dns_ip=$(${pkgs.dnsutils}/bin/dig -4 +short anastasia.niols.fr @${server}.niols.fr); then
    #             echo "Done checking DNS record; got $dns_ip." >&2
    #             if [ "$current_ip" = "$dns_ip" ]; then
    #               echo "The DNS record does contain the correct IP already." >&2
    #             else
    #               echo "Updating DNS record on ${server} to $current_ip..." >&2
    #               ${pkgs.dnsutils}/bin/nsupdate -k ${config.age.secrets.bind-key-anastasia-ddns.path} <<-EOF
    #                 server ${server}.niols.fr
    #                 zone niols.fr
    #                 update delete anastasia.niols.fr A
    #                 update add anastasia.niols.fr 60 A $current_ip
    #                 send
    #           EOF
    #               echo "Done updating DNS record on ${server}." >&2
    #             fi
    #           else
    #             echo "Failed checking DNS record; dig exited with error code $?." >&2
    #             failure=true
    #           fi
    #         ''
    #       )}
    #       if $failure; then exit 1; fi
    #     '';
    #     serviceConfig.Type = "oneshot";
    #     requires = [ "network-online.target" ]; # fails if network isn't online
    #     after = [ "network-online.target" ]; # only runs after network is online
    #     ## NOTE: this `wantedBy` might be why the unit triggers on `nixos-rebuild`, so I removed it as of 3 June 2026
    #     # wantedBy = [ "network-online.target" ]; # runs when network comes online;
    #   };

    #   systemd.timers.update-dns-with-public-ip = {
    #     wantedBy = [ "timers.target" ];
    #     timerConfig.OnCalendar = "*:0/1"; # every minute
    #   };
    # })
  ];
}
