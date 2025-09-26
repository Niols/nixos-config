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
    "${name}.age".publicKeys = [
      keys.niols.default
      keys.secrets-backup
    ]
    ++ machines;
  })

  (
    with keys;
    with machines;

    {
      ############################################################################
      ## Files and their host keys

      atticd-environment = [ siegfried ];

      dancelor-database-repository = [ helga ];
      dancelor-github-token = [ helga ];

      password-ahlaya-niols = [ ahlaya ];
      password-ahlaya-root = [ ahlaya ];
      password-ahlaya-work = [ ahlaya ];
      password-gromit-niols = [ gromit ];
      password-gromit-root = [ gromit ];
      password-helga-niols = [ helga ];
      password-helga-root = [ helga ];
      password-orianne-root = [ orianne ];
      password-siegfried-root = [ siegfried ];

      syncthing-siegfried-passwd = [ siegfried ];
      syncthing-siegfried-cert = [ siegfried ];
      syncthing-siegfried-key = [ siegfried ];
      syncthing-ahlaya-cert = [ ahlaya ];
      syncthing-ahlaya-key = [ ahlaya ];
      syncthing-gromit-cert = [ gromit ];
      syncthing-gromit-key = [ gromit ];

      hester-atticd-backup-repokey = [ siegfried ];
      hester-atticd-backup-identity = [ siegfried ];
      hester-samba-credentials = [
        helga
        orianne
        siegfried
        ahlaya
        gromit
      ];
      hester-matrix-backup-repokey = [ helga ];
      hester-matrix-backup-identity = [ helga ];
      hester-niolscloud-backup-repokey = [ orianne ];
      hester-niolscloud-backup-identity = [ orianne ];
      hester-syncthing-backup-repokey = [ siegfried ];
      hester-syncthing-backup-identity = [ siegfried ];
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

      nix-netrc = [ home-manager ];

      rutorrent-passwd = [ helga ];

      wireguard-ahlaya-ahrefs-key = [ ahlaya ];
    }
  )
