{ config, pkgs, lib, ... }: {

  ## NOTE: This file is very heavily inspired by the NixOS module
  ## `programs.rust-motd`:
  ##
  ## https://github.com/NixOS/nixpkgs/blob/041094ad2ff90eab7d3d044c3eaad463666d2caa/nixos/modules/programs/rust-motd.nix
  ##
  ## Ideally, we would even use that NixOS module, but it has a severe issue
  ## making it unusable in practice for us:
  ##
  ## https://github.com/NixOS/nixpkgs/issues/234802

  options.niols-motd = with lib; {
    enable = mkEnableOption (mdDoc "niols-motd");

    hostname = mkOption {
      type = types.str;
      description = mdDoc "Name of the machine; pretty.";
    };

    hostcolour = mkOption {
      type = types.str;
      description = mdDoc "Colour of the machine.";
    };

    noSwap = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Whether to hide swap from memory.";
    };
  };

  config = lib.mkIf config.niols-motd.enable {

    assertions = [
      {
        assertion = config.users.motd == null;
        message = "Should not use both `users.motd` and `niols-motd`.";
      }
      {
        assertion = config.programs.rust-motd.enable == false;
        message = "Should not use both `programs.rust-motd` and `niols-motd`.";
      }
    ];

    systemd.services.update-motd = {
      path = with pkgs; [ bash figlet ];

      serviceConfig = {
        ExecStart = let
          motd-config = pkgs.writeTextFile {
            name = "motd.toml";
            text = ''
              [global]
              progress_full_character = "#"
              progress_empty_character = "-"
              progress_prefix = "["
              progress_suffix = "]"
              time_format = "%Y-%m-%d %H:%M:%S"

              [banner]
              color = "${config.niols-motd.hostcolour}"
              command = """
                printf -- '\\033[1m%s\\033[0m' "$(echo ${config.niols-motd.hostname} | figlet -f standard)"
              """

              [uptime]
              prefix = "Up"

              [filesystems]
              root = "/"
              boot = "/boot"

              [memory]
              swap_pos = "${if config.niols-motd.noSwap then "none" else "beside"}"
            '';
          };
        in "${pkgs.writeShellScript "update-motd" ''
          ${pkgs.rust-motd}/bin/rust-motd ${motd-config} > /var/run/motd.dynamic
        ''}";

        CapabilityBoundingSet = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectKernelTunables = true;
        ProtectSystem = "full";
        StateDirectory = "niols-motd";
        RestrictAddressFamilies = [ "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        WorkingDirectory = "/var/lib/niols-motd";
      };
    };

    systemd.timers.update-motd = {
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = "*:0/5";
    };

    security.pam.services.sshd.text = lib.mkDefault (lib.mkAfter ''
      session optional ${pkgs.pam}/lib/security/pam_motd.so motd=/var/run/motd.dynamic
    '');

    services.openssh.extraConfig = ''
      PrintLastLog no
    '';
  };
}
