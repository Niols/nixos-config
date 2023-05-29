{ config, pkgs, lib, ... }: {

  assertions = [ {
    assertion = config.users.motd == null;
    message = "Should not use both `users.motd` and my custom configuration.";
  } ];

  systemd.services.update-motd = {
    path = with pkgs; [ bash figlet ];

    serviceConfig = {
      ExecStart = "${pkgs.writeShellScript "update-motd" ''
        cat > motd.conf <<EOF
          [global]
          progress_full_character = "#"
          progress_empty_character = "-"
          progress_prefix = "["
          progress_suffix = "]"
          time_format = "%Y-%m-%d %H:%M:%S"

          [banner]
          color = "yellow"
          command = "echo Siegfried | figlet -f standard"

          [uptime]
          prefix = "Up"

          [user_service_status]
          gpg-agent = "gpg-agent"

          [filesystems]
          root = "/"
          boot = "/boot"

          [memory]
          swap_pos = "below"

          [last_login]
          root = 5
          niols = 5
        EOF
        ${pkgs.rust-motd}/bin/rust-motd motd.conf > /var/run/motd.dynamic
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
      StateDirectory = "rust-motd";
      RestrictAddressFamilies = [ "AF_UNIX" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      WorkingDirectory = "/var/lib/rust-motd";
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
}
