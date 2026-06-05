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
    with keys.homes;
    with keys.machines;

    {
      ############################################################################
      ## Files and their host keys

      atticd-environment = [ anastasia ];
      attic-client-config = [
        ahlaya-niols
        ahlaya-work
        gromit-niols
      ];

      bind-key-anastasia-ddns = [
        anastasia
        helga
        orianne
        siegfried
      ];

      dancelor-github-token = [ orianne ];

      grafana-secret-key = [ orianne ];

      ## NOTE: The following passwords need to be hashed in an encrypted form,
      ## which can be done with the `mkpasswd` command.
      password-ahlaya-niols = [ ahlaya ];
      password-ahlaya-root = [ ahlaya ];
      password-anastasia-niols = [ anastasia ];
      password-anastasia-root = [ anastasia ];
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

      hester-atticd-backup-repokey = [ anastasia ];
      hester-atticd-backup-identity = [ anastasia ];
      hester-dancelor-backup-repokey = [ orianne ];
      hester-dancelor-backup-identity = [ orianne ];
      hester-samba-credentials = [
        anastasia
        helga
        orianne
        siegfried
        ahlaya
        gromit
      ];
      hester-git-backup-repokey = [ anastasia ];
      hester-git-backup-identity = [ anastasia ];
      hester-grafana-backup-repokey = [ orianne ];
      hester-grafana-backup-identity = [ orianne ];
      hester-jellyfin-backup-repokey = [ anastasia ];
      hester-jellyfin-backup-identity = [ anastasia ];
      hester-matrix-backup-repokey = [ helga ];
      hester-matrix-backup-identity = [ helga ];
      hester-niolscloud-backup-repokey = [ orianne ];
      hester-niolscloud-backup-identity = [ orianne ];
      hester-syncthing-backup-repokey = [ siegfried ];
      hester-syncthing-backup-identity = [ siegfried ];
      hester-teamspeak-backup-repokey = [ helga ];
      hester-teamspeak-backup-identity = [ helga ];
      hester-web-backup-repokey = [ helga ];
      hester-web-backup-identity = [ helga ];

      ftp-password-kerl = [ siegfried ];

      mastodon-noreply-password = [ siegfried ];

      no-reply-smtp-password = [ orianne ];

      matrix-synapse-signing-key = [ helga ];
      matrix-synapse-macaroon-secret = [ helga ];
      matrix-synapse-registration-secret = [ helga ];

      mosquitto-password-nrg_dongle_pro = [ orianne ];
      mosquitto-password-telegraf = [ orianne ];
      telegraf-secrets = [ orianne ];

      netrc-niols = [
        ahlaya-niols
        ahlaya-work
        gromit-niols
      ];
      netrc-work = [
        headless-work
      ];

      niolscloud-admin-password = [ orianne ];
      niolscloud-secrets = [ orianne ];
      niolscloud-exporter-token = [ orianne ];

      ## Read-only authentication to substituters. This is distributed widely
      ## and should not contain sensitive tokens. See `attic-client-config` for
      ## write- or godlike- powers.
      nix-client-netrc = [
        ahlaya
        anastasia
        gromit
        helga
        orianne
        siegfried
        # homes:
        ahlaya-niols
        ahlaya-work
        gromit-niols
        headless-work
      ];

      rclone-gdrive-client-id = [
        ahlaya-niols
        gromit-niols
      ];
      rclone-gdrive-client-secret = [
        ahlaya-niols
        gromit-niols
      ];
      rclone-gdrive-token = [
        ahlaya-niols
        gromit-niols
      ];

      postgresql-password-grafana = [ orianne ];

      rutorrent-passwd = [ helga ];

      wireguard-ahlaya-ahrefs-key = [ ahlaya ];

      wireguard-anastasia-niols-key = [ anastasia ];
      wireguard-helga-niols-key = [ helga ];
      wireguard-orianne-niols-key = [ orianne ];
      wireguard-siegfried-niols-key = [ siegfried ];
    }
  )
