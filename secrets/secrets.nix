let
  inherit (builtins) attrValues foldl' mapAttrs;
  ## `mergeAttrs` and `concatMapAttrs` are in `lib.trivial` and `lib.attrsets`,
  ## but we would rather avoid a dependency in nixpkgs for this file.
  mergeAttrs = x: y: x // y;
  concatMapAttrs = f: v: foldl' mergeAttrs { } (attrValues (mapAttrs f v));

  keys = import ../keys/keys.nix;
in

concatMapAttrs
  (name: machines: {
    "${name}.age".publicKeys = attrValues keys.niols ++ machines;
  })

  (
    with keys.machines;
    with keys.niols;

    {
      ############################################################################
      ## Files and their host keys

      dancelor-passwd = [ dagrun ];
      dancelor-database-repository = [ dagrun ];
      password-dagrun-niols = [ dagrun ];
      password-orianne-niols = [ orianne ];
      password-siegfried-niols = [ siegfried ];

      firefly-iii-app-key-file = [ siegfried ];
      firefly-iii-data-importer-nordigen-id = [ siegfried ];
      firefly-iii-data-importer-nordigen-key = [ siegfried ];

      syncthing-siegfried-passwd = [ siegfried ];
      syncthing-siegfried-cert = [ siegfried ];
      syncthing-siegfried-key = [ siegfried ];

      syncthing-wallace-cert = [ wallace ];
      syncthing-wallace-key = [ wallace ];

      hester-samba-credentials = [
        dagrun
        orianne
        siegfried
        wallace
      ];
      hester-matrix-backup-repokey = [ dagrun ];
      hester-matrix-backup-identity = [ dagrun ];
      hester-niolscloud-backup-repokey = [ orianne ];
      hester-niolscloud-backup-identity = [ orianne ];
      hester-syncthing-backup-repokey = [ siegfried ];
      hester-syncthing-backup-identity = [ siegfried ];
      hester-firefly-iii-backup-repokey = [ siegfried ];
      hester-firefly-iii-backup-identity = [ siegfried ];
      hester-git-backup-repokey = [ siegfried ];
      hester-git-backup-identity = [ siegfried ];
      hester-web-backup-repokey = [ siegfried ];
      hester-web-backup-identity = [ siegfried ];

      ftp-password-kerl = [ siegfried ];

      mastodon-noreply-password = [ siegfried ];

      matrix-synapse-signing-key = [ dagrun ];
      matrix-synapse-macaroon-secret = [ dagrun ];
      matrix-synapse-registration-secret = [ dagrun ];

      niolscloud-admin-password = [ orianne ];
      niolscloud-secrets = [ orianne ];

      vaultwarden-environment = [ siegfried ];

      wireguard-wallace-fediversity-private-key = [ wallace ];

      ## See section “Key Files” of
      ## https://openvpn.net/community-resources/how-to/#determining-whether-to-use-a-routed-or-bridged-vpn
      ## for more information on which is actually secret and which is not.
      vpn-ca-crt = [
        orianne
        wallace
      ];
      vpn-dh-pem = [ orianne ];
      vpn-orianne-crt = [ orianne ];
      vpn-orianne-key = [ orianne ];
      vpn-wallace-crt = [ wallace ];
      vpn-wallace-key = [ wallace ];
    }
  )
