{ config, secrets, dancelor, pkgs, ... }:

let
  system = "x86_64-linux";
  lilypond' = dancelor.inputs.nixpkgs.legacyPackages.${system}.lilypond;
  inkscape' = dancelor.inputs.nixpkgs.legacyPackages.${system}.inkscape;
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
    runtimeInputs = (with pkgs; [ git freepats xvfb-run ])
      ++ [ inkscape' lilypond' timidity' ];
    text = ''
      ${dancelor'}/bin/dancelor-server \
        --cache /var/cache/dancelor \
        --database /var/lib/dancelor/database \
        --share ${dancelor'}/share/dancelor \
        --loglevel debug \
        --port 6872
    '';
  };

in {
  users.users.dancelor = {
    isSystemUser = true;
    home = "/var/lib/dancelor";
    group = "dancelor";
  };
  users.groups.dancelor = { };

  ## Necessary for Inkscape to find the accessibility bus.
  services.gnome.at-spi2-core.enable = true;

  systemd.services.dancelor-init = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${init-dancelor}/bin/init-dancelor";
      Type = "oneshot";
    };
  };

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

  nix.settings = {
    substituters = [ "https://dancelor.cachix.org" ];
    trusted-public-keys =
      [ "dancelor.cachix.org-1:Q2pAI0MA6jIccQQeT8JEsY+Wfwb/751zmoUHddZmDyY=" ];
  };

  age.secrets.dancelor-passwd = {
    file = "${secrets}/dancelor-passwd.age";
    mode = "600";
    owner = "nginx";
    group = "nginx";
  };

  age.secrets.dancelor-database-repository = {
    file = "${secrets}/dancelor-database-repository.age";
  };

  services.nginx.virtualHosts.dancelor = {
    serverName = "new.dancelor.org";

    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:6872";
      basicAuthFile = config.age.secrets.dancelor-passwd.path;
    };
  };
}
