{ config, secrets, dancelor, pkgs, ... }:

let
  system = "x86_64-linux";
  lilypond' = dancelor.inputs.nixpkgs.legacyPackages.${system}.lilypond;
  timidity' = dancelor.inputs.timidity.packages.${system}.timidityWithVorbis;
  dancelor' = dancelor.packages.${system}.dancelor;

  init-dancelor = pkgs.writeShellApplication {
    name = "init-dancelor";
    runtimeInputs = with pkgs; [ git ];
    excludeShellChecks = [ "SC2016" ];
    text = ''
      mkdir -p /var/cache/dancelor/{version,set,book}
      mkdir -p /var/lib/dancelor

      ## Test whether the given path is a Git repository owned by 'dancelor'.
      is_dancelor_git_repository () (
        cd "$1" && ${pkgs.su}/bin/su -s /bin/sh dancelor -c \
          'test "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true'
      )

      if [ -e /var/lib/dancelor/database ]; then
        if ! is_dancelor_git_repository /var/lib/dancelor/database; then
          echo "The directory '/var/lib/dancelor/database' exists but is not a Git repository." >&2
          exit 1
        fi
      else
        git clone "$(cat ${config.age.secrets.dancelor-database-repository.path})" /var/lib/dancelor/database
      fi

      chown -R dancelor:dancelor /var/cache/dancelor
      chown -R dancelor:dancelor /var/lib/dancelor
    '';
  };

  run-dancelor = pkgs.writeShellApplication {
    name = "run-dancelor";
    runtimeInputs = (with pkgs; [ git freepats ]) ++ [ lilypond' timidity' ];
    text = ''
      ${dancelor'}/bin/dancelor \
        --cache /var/cache/dancelor \
        --database /var/lib/dancelor/database \
        --share ${dancelor'}/share/dancelor \
        --loglevel info \
        --port 6872
    '';
  };

in {
  ## Create a user and a group `dancelor:dancelor`.
  users.users.dancelor = {
    isSystemUser = true;
    ## LilyPond needs a home to cache fonts.
    home = "/var/lib/dancelor";
    group = "dancelor";
  };
  users.groups.dancelor = { };

  ## Initialisation service. Runs once as root so as to create the right
  ## directories for the actual service which will run as `dancelor`.
  systemd.services.dancelor-init = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${init-dancelor}/bin/init-dancelor";
      Type = "oneshot";
    };
  };

  ## Actual service that runs `dancelor`. Requires the service above. Runs as
  ## `dancelor:dancelor`.
  systemd.services.dancelor = {
    after = [ "network.target" "dancelor-init.service" ];
    requires = [ "dancelor-init.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${run-dancelor}/bin/run-dancelor";
      Restart = "always";
      User = "dancelor";
      Group = "dancelor";
    };
  };

  ## Use Dancelor's Cachix instance as a substituter. Since Dancelor's CI fill
  ## it with all the components, this should make things much faster.
  nix.settings = {
    substituters = [ "https://dancelor.cachix.org" ];
    trusted-public-keys =
      [ "dancelor.cachix.org-1:Q2pAI0MA6jIccQQeT8JEsY+Wfwb/751zmoUHddZmDyY=" ];
  };

  ## A secret `passwd` file containing the users' identifiers.
  age.secrets.dancelor-passwd = {
    file = "${secrets}/dancelor-passwd.age";
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  ## A secret Git repository for the database. It will be cloned by the
  ## `dancelor-init` service and used by the `dancelor` service.
  age.secrets.dancelor-database-repository = {
    file = "${secrets}/dancelor-database-repository.age";
  };

  ## A simple Nginx proxy in front of Dancelor. Handles HTTPS, the generation of
  ## the certificate, and the `passwd` authentication.
  services.nginx.virtualHosts.dancelor = {
    serverName = "dancelor.org";
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:6872";
      basicAuthFile = config.age.secrets.dancelor-passwd.path;
      extraConfig = ''
        ## Dancelor relies on SVGs being embedded as objects, which can trigger
        ## the `X-Frame-Options` policy. We therefore relax it a tiny bit
        ## (compared to `DENY`). We also have to include other headers otherwise
        ## they are dropped, because `add_header` replaces all parent headers.
        ## cf http://nginx.org/en/docs/http/ngx_http_headers_module.html#add_header
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
      '';
    };
  };
}
