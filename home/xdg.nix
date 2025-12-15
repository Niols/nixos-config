{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    mkMerge
    types
    ;

in
{
  options.home.x_niols.xdgRuntimeDir = mkOption {
    description = ''
      The value of $XDG_RUNTIME_DIR, if it can be predicted, and `null`
      otherwise. We cannot be 100% sure, because this value is normally set at
      runtime, but we need it in a few places in this configuration. We will
      check at activation time that the value is indeed what we predicted here.
    '';
    type = with types; nullOr str;
    default =
      ## NOTE: We should be able to use config.home.uid but
      ## https://github.com/nix-community/home-manager/issues/8351
      let
        uid = osConfig.users.users.${config.home.username}.uid or null;
      in
      if uid != null then "/run/user/${toString uid}" else null;
    readOnly = true;
  };

  config = mkMerge [
    (mkIf (config.home.x_niols.xdgRuntimeDir != null) {
      ## Check that XDG_RUNTIME_DIR is what we expected when building the
      ## configuration. Ideally, we would have a check as a systemd unit, but it
      ## would not give good reporting, so it will live in [...] for now.
      systemd.user.services.check-xdg-runtime-dir = {
        Unit = {
          Description = "Check XDG_RUNTIME_DIR is properly set";
          After = [ "basic.target" ];
        };
        Install.WantedBy = [ "default.target" ];

        Service = {
          Type = "oneshot";
          ExecStart =
            let
              checkScript = pkgs.writeShellScript "check-xdg-runtime-dir" ''
                expected=${config.home.x_niols.xdgRuntimeDir}
                actual=%t
                if [ "$actual" != "$expected" ]; then
                  echo "The variable XDG_RUNTIME_DIR is not what was expected!"
                  echo "  - expected: $expected"
                  echo "  - actual: $actual"
                  echo "Note that this is the actual value _before_ this Home"
                  echo "manager generation is activated. If you think the value"
                  echo "of XDG_RUNTIME_DIR has changed for a good reason, then"
                  echo "you will have to work around activating this generation"
                  echo "manually to get things back in sync."
                  exit 2
                fi
              '';
            in
            "${checkScript}";
        };
      };
    })

    (mkIf (!config.x_niols.isHeadless) {
      xdg.userDirs = {
        enable = true;
        desktop = "${config.home.homeDirectory}";
        createDirectories = false;
      };

      xdg.autostart = {
        enable = true;
        readOnly = true; # more reproducibility, and avoid apps like Nextcloud starting twice
      };
    })

    (mkIf (!config.x_niols.isHeadless && !config.x_niols.isWork) {
      xdg.userDirs = {
        documents = "${config.home.homeDirectory}/NiolsCloud/Documents";
        music = "${config.home.homeDirectory}/NiolsCloud/Médias/Music";
        pictures = "${config.home.homeDirectory}/NiolsCloud/Images";
        videos = "${config.home.homeDirectory}/NiolsCloud/Médias";
      };
    })
  ];
}
