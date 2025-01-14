{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;

in
{
  options.x_niols.autoreboot = {
    enable = mkEnableOption { };
  };

  config = mkIf config.x_niols.autoreboot.enable {
    systemd.timers."daily-reboot" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 05:00:00";
        Persistent = true;
      };
    };

    systemd.services."daily-reboot" = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl reboot";
      };
    };
  };
}
