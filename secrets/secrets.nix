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

    {
      ############################################################################
      ## Files and their host keys

      dancelor-database-repository = [ helga ];
      dancelor-github-token = [ helga ];

      password-helga-niols = [ helga ];
      password-orianne-niols = [ orianne ];
      password-siegfried-niols = [ siegfried ];

      firefly-iii-app-key-file = [ siegfried ];
      firefly-iii-data-importer-nordigen-id = [ siegfried ];
      firefly-iii-data-importer-nordigen-key = [ siegfried ];

      syncthing-siegfried-passwd = [ siegfried ];
      syncthing-siegfried-cert = [ siegfried ];
      syncthing-siegfried-key = [ siegfried ];
      syncthing-ahlaya-cert = [ ahlaya ];
      syncthing-ahlaya-key = [ ahlaya ];
      syncthing-gromit-cert = [ gromit ];
      syncthing-gromit-key = [ gromit ];
      syncthing-wallace-cert = [ wallace ];
      syncthing-wallace-key = [ wallace ];

      hester-samba-credentials = [
        helga
        orianne
        siegfried
        ahlaya
        gromit
        wallace
      ];
      hester-matrix-backup-repokey = [ helga ];
      hester-matrix-backup-identity = [ helga ];
      hester-niolscloud-backup-repokey = [ orianne ];
      hester-niolscloud-backup-identity = [ orianne ];
      hester-syncthing-backup-repokey = [ siegfried ];
      hester-syncthing-backup-identity = [ siegfried ];
      hester-firefly-iii-backup-repokey = [ siegfried ];
      hester-firefly-iii-backup-identity = [ siegfried ];
      hester-git-backup-repokey = [ siegfried ];
      hester-git-backup-identity = [ siegfried ];
      hester-jellyfin-backup-repokey = [ orianne ];
      hester-jellyfin-backup-identity = [ orianne ];
      hester-teamspeak-backup-repokey = [ helga ];
      hester-teamspeak-backup-identity = [ helga ];
      hester-web-backup-repokey = [ helga ];
      hester-web-backup-identity = [ helga ];

      ftp-password-kerl = [ siegfried ];

      mastodon-noreply-password = [ siegfried ];

      matrix-synapse-signing-key = [ helga ];
      matrix-synapse-macaroon-secret = [ helga ];
      matrix-synapse-registration-secret = [ helga ];

      niolscloud-admin-password = [ orianne ];
      niolscloud-secrets = [ orianne ];

      rutorrent-passwd = [ helga ];
    }
  )
