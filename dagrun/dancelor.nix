{ config, secrets, dancelor, pkgs, ... }:

let
  dancelor' = dancelor.packages.x86_64-linux.dancelor;

  init-dancelor = pkgs.writeShellApplication {
    name = "init-dancelor";
    text = ''
      mkdir -p \
        /var/cache/dancelor/{version,set,book} \
        /var/lib/dancelor/database

      chown -R dancelor:dancelor \
        /var/cache/dancelor \
        /var/lib/dancelor/database
    '';
  };

  run-dancelor = pkgs.writeShellApplication {
    name = "run-dancelor";
    runtimeInputs = with pkgs; [
      git
      inkscape
      lilypond
      timidity
      freepats
      xvfb-run
    ];
    text = ''
      ${dancelor'}/bin/dancelor-server \
        --cache /var/cache/dancelor \
        --database /var/lib/dancelor/database \
        --loglevel info \
        --port 6872 \
        --share ${dancelor'}/share
    '';
  };

in {
  users.users.dancelor = {
    isSystemUser = true;
    group = "dancelor";
  };
  users.groups.dancelor = { };

  systemd.services.dancelor-init = {
    serviceConfig = { ExecStart = "${init-dancelor}/bin/init-dancelor"; };
  };

  systemd.services.dancelor = {
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
