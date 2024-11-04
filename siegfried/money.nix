{
  config,
  secrets,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib.strings)
    concatLines
    toShellVars
    removeSuffix
    hasSuffix
    ;
  inherit (lib.attrsets)
    mapAttrsToList
    genAttrs
    filterAttrs
    mapAttrs'
    nameValuePair
    ;

  url = "money.niols.fr";
  dataDir = "/var/lib/firefly-iii";

  ## Data Importer. FIXME: This violates the way flakes work. This should be
  ## moved to nixpkgs, maybe even contributed to the Firefly III package?
  cfg = config.services.firefly-iii;
  diDataDir = "${cfg.dataDir}/data-importer";
  diUrlPrefix = "/import";
  diSettings = { };
  diVer = "1.5.4";
  diSrc = pkgs.stdenv.mkDerivation rec {
    name = "firefly-iii-data-importer-${diVer}";
    src = pkgs.fetchzip {
      url = "https://github.com/firefly-iii/data-importer/releases/download/v${diVer}/DataImporter-v${diVer}.tar.gz";
      hash = "sha256-erRxufz45ZWILKb4agimp7C3h30hZKX2Q9pDE949wPE=";
      stripRoot = false;
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir $out
      ${pkgs.rsync}/bin/rsync -a ${src}/ $out --exclude=storage
      chmod +w $out
      ln -s ${diDataDir}/storage $out/storage
      cat <<EOF > $out/.env
      FIREFLY_III_URL=https://money.niols.fr
      FIREFLY_III_CLIENT_ID=3
      NORDIGEN_ID_FILE=${config.age.secrets.firefly-iii-data-importer-nordigen-id.path}
      NORDIGEN_KEY_FILE=${config.age.secrets.firefly-iii-data-importer-nordigen-key.path}
      GOCARDLESS_GET_ACCOUNT_DETAILS=true
      GOCARDLESS_GET_BALANCE_DETAILS=true
      TRUSTED_PROXIES="*"
      LOG_LEVEL=debug
      ASSET_URL=${diUrlPrefix}

      ## Must match the timezone of the banks you're importing from.
      TZ=Europe/Amsterdam
      EOF
    '';
  };

  di-env-file-values = mapAttrs' (n: v: nameValuePair (removeSuffix "_FILE" n) v) (
    filterAttrs (n: _v: hasSuffix "_FILE" n) diSettings
  );
  di-env-nonfile-values = filterAttrs (n: _v: !hasSuffix "_FILE" n) diSettings;

  firefly-iii-data-importer-maintenance = pkgs.writeShellScript "firefly-iii-data-importer-maintenance.sh" ''
    set -a
    ${toShellVars di-env-nonfile-values}
    ${concatLines (mapAttrsToList (n: v: "${n}=$(< ${v})") di-env-file-values)}
    set +a
  '';

  ## FIXME: Almost copied as-is from Firefly III
  commonServiceConfig = {
    Type = "oneshot";
    User = cfg.user;
    Group = cfg.group;
    StateDirectory = "firefly-iii-data-importer";
    ReadWritePaths = [ diDataDir ];
    WorkingDirectory = diSrc;
    PrivateTmp = true;
    PrivateDevices = true;
    CapabilityBoundingSet = "";
    AmbientCapabilities = "";
    ProtectSystem = "strict";
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectHome = "tmpfs";
    ProtectKernelLogs = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    PrivateNetwork = false;
    RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service @resources"
      "~@obsolete @privileged"
    ];
    RestrictSUIDSGID = true;
    RemoveIPC = true;
    NoNewPrivileges = true;
    RestrictRealtime = true;
    RestrictNamespaces = true;
    LockPersonality = true;
    PrivateUsers = true;
  };

in
{
  services.firefly-iii = {
    enable = true;

    inherit dataDir;

    enableNginx = true;
    virtualHost = url;

    settings = {
      APP_URL = url;
      APP_KEY_FILE = config.age.secrets.firefly-iii-app-key-file.path;

      ## Must match the timezone of the banks you're importing from.
      TZ = "Europe/Amsterdam";
    };
  };

  ## FIXME: Re-enable when merging cleanly with data importer
  # services.nginx.virtualHosts.${url} = {
  #   forceSSL = true;
  #   enableACME = true;
  # };

  age.secrets.firefly-iii-app-key-file = {
    file = "${secrets}/firefly-iii-app-key-file.age";
    mode = "600";
    owner = "firefly-iii";
  };

  age.secrets.firefly-iii-data-importer-nordigen-id = {
    file = "${secrets}/firefly-iii-data-importer-nordigen-id.age";
    mode = "600";
    owner = "firefly-iii";
  };

  age.secrets.firefly-iii-data-importer-nordigen-key = {
    file = "${secrets}/firefly-iii-data-importer-nordigen-key.age";
    mode = "600";
    owner = "firefly-iii";
  };

  ## Backup

  services.borgbackup.jobs.money = {
    startAt = "*-*-* 05:00:00";

    paths = [ dataDir ];

    repo = "ssh://u363090@hester.niols.fr:23/./backups/money";
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.age.secrets.hester-firefly-iii-backup-repokey.path}";
    };
    environment.BORG_RSH = "ssh -i ${config.age.secrets.hester-firefly-iii-backup-identity.path}";
  };

  age.secrets.hester-firefly-iii-backup-identity.file = "${secrets}/hester-firefly-iii-backup-identity.age";
  age.secrets.hester-firefly-iii-backup-repokey.file = "${secrets}/hester-firefly-iii-backup-repokey.age";

  ############################################################################
  ############################################################################
  ############################################################################

  ## Firefly needs it to be able to format all types of currencies and dates.
  ## Rather than specifying only the exact subset of locales, we support them
  ## all. FIXME: This should be in another file, somewhere else.
  i18n.supportedLocales = [ "all" ];

  services.phpfpm.pools.firefly-iii-data-importer = {
    inherit (cfg) user group;
    phpPackage = cfg.package.phpPackage;
    phpOptions = ''
      log_errors = on
    '';
    settings = {
      "listen.mode" = "0660";
      "listen.owner" = cfg.user;
      "listen.group" = cfg.group;
      "clear_env" = "no";
    } // cfg.poolConfig;
  };

  systemd.services.firefly-iii-data-importer-setup = {
    after = [
      "postgresql.service"
      "mysql.service"
    ];
    requiredBy = [ "phpfpm-firefly-iii-data-importer.service" ];
    before = [ "phpfpm-firefly-iii-data-importer.service" ];
    serviceConfig = {
      ExecStart = firefly-iii-data-importer-maintenance;
      RemainAfterExit = true;
    } // commonServiceConfig;
    unitConfig.JoinsNamespaceOf = "phpfpm-firefly-iii-data-importer.service";
    restartTriggers = [ cfg.package ];
  };

  services.nginx.virtualHosts.${url} = {
    forceSSL = true;
    enableACME = true;

    locations = {
      "= ${diUrlPrefix}".extraConfig = ''
        return 301 ${diUrlPrefix}/;
      '';

      "${diUrlPrefix}/" = {
        alias = "${diSrc}/public/";
        ## NOTE: The double `diUrlPrefix` and the middle `/` are not mistakes
        ## but a mitigation of https://trac.nginx.org/nginx/ticket/97
        tryFiles = "$uri $uri/ ${diUrlPrefix}/${diUrlPrefix}/index.php?$query_string";
        index = "index.php";
        extraConfig = ''
          sendfile off;

          location ~ \.php$ {
            include ${config.services.nginx.package}/conf/fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $request_filename;
            fastcgi_param modHeadersAvailable true; #Avoid sending the security headers twice
            fastcgi_pass unix:${config.services.phpfpm.pools.firefly-iii-data-importer.socket};
          }
        '';
      };
    };
  };

  systemd.tmpfiles.settings."10-firefly-iii-data-importer" =
    genAttrs
      [
        "${diDataDir}/storage"
        "${diDataDir}/storage/app"
        "${diDataDir}/storage/app/public"
        "${diDataDir}/storage/configurations"
        "${diDataDir}/storage/conversion-routines"
        "${diDataDir}/storage/debugbar"
        "${diDataDir}/storage/framework"
        "${diDataDir}/storage/framework/cache"
        "${diDataDir}/storage/framework/cache/data"
        "${diDataDir}/storage/framework/sessions"
        "${diDataDir}/storage/framework/testing"
        "${diDataDir}/storage/framework/views"
        "${diDataDir}/storage/jobs"
        "${diDataDir}/storage/logs"
        "${diDataDir}/storage/submission-routines"
        "${diDataDir}/storage/uploads"
      ]
      (_n: {
        d = {
          group = cfg.group;
          mode = "0700";
          user = cfg.user;
        };
      })
    // {
      "${diDataDir}".d = {
        group = cfg.group;
        mode = "0710";
        user = cfg.user;
      };
    };
}
