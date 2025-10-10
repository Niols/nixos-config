{
  config,
  pkgs,
  lib,
  machines,
  ...
}:

let
  inherit (lib)
    toSentenceCase
    ;

in
{
  ## NOTE: This file is very heavily inspired by the NixOS module
  ## `programs.rust-motd`:
  ##
  ## https://github.com/NixOS/nixpkgs/blob/041094ad2ff90eab7d3d044c3eaad463666d2caa/nixos/modules/programs/rust-motd.nix
  ##
  ## Ideally, we would even use that NixOS module, but it has a severe issue
  ## making it unusable in practice for us:
  ##
  ## https://github.com/NixOS/nixpkgs/issues/234802

  assertions = [
    {
      assertion = config.users.motd == null || config.users.motd == false || config.users.motd == "";
      message = "Should not use `users.motd`.";
    }
    {
      assertion = config.programs.rust-motd.enable == false;
      message = "Should not use `programs.rust-motd`.";
    }
  ];

  systemd.services.update-motd = {
    path = with pkgs; [
      bash
      figlet
    ];

    serviceConfig = {
      ExecStart =
        let
          motd-config = pkgs.writeTextFile {
            name = "motd.kdl";
            text = ''
              global {
                version "1.0"
                progress-full-character "#"
                progress-empty-character "-"
                progress-prefix "["
                progress-suffix "]"
                time-format "%Y-%m-%d %H:%M:%S"
              }

              components {
                command color="${config.x_niols.thisMachinesColour}" "
                  printf -- '\\033[1m%s\\033[0m' \"$(echo ${toSentenceCase config.x_niols.thisMachinesName} | figlet -f standard)\"
                "

                uptime prefix="Uptime"

                filesystems {
                  filesystem name="root" mount-point="/"
                  filesystem name="boot" mount-point="/boot"
                }

                memory swap-pos="${
                  ## REVIEW: Maybe grab this information from disko?
                  if machines.this.kind == "server" then "none" else "beside"
                }"
              }
            '';
          };
        in
        "${pkgs.writeShellScript "update-motd" ''
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

  security.pam.services.sshd.text = lib.mkDefault (
    lib.mkAfter ''
      session optional ${pkgs.pam}/lib/security/pam_motd.so motd=/var/run/motd.dynamic
    ''
  );

  services.openssh.extraConfig = ''
    PrintLastLog no
  '';
}
