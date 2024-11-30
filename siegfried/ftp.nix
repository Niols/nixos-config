{ config, secrets, ... }:

let
  inherit (builtins) toString;

  pasvMinPort = 30000;
  pasvMaxPort = 31000;

in
{
  services.vsftpd = {
    enable = true;

    ## Disable anonymous user (should be the default, but still). Use only local
    ## users. Enable userlist; only users in the list are allowed to login.
    localUsers = true;
    anonymousUser = false;
    userlistEnable = true;
    userlistDeny = false;
    userlist = [ "kerl" ];

    ## Confine users to their home directories. Allow them write access to it.
    writeEnable = true;
    chrootlocalUser = true;
    allowWriteableChroot = true;

    ## Security: SSL everywhere. Use the certificate provided by nginx.
    forceLocalLoginsSSL = true;
    forceLocalDataSSL = true;
    rsaKeyFile = "/var/lib/acme/ftp.niols.fr/key.pem";
    rsaCertFile = "/var/lib/acme/ftp.niols.fr/cert.pem";

    extraConfig = ''
      ## More security: prevent SSL reuse and use only high-quality ciphers.
      ## This is more than hardening and it will be impossible to establish an SSL
      ## connection without this.
      require_ssl_reuse=NO
      ssl_ciphers=HIGH

      ## Enable passive mode between the ports 30000 and 31000.
      pasv_enable=YES
      pasv_min_port=${toString pasvMinPort}
      pasv_max_port=${toString pasvMaxPort}
    '';
  };

  ## Open the ports. No need to open 20, only used in active mode; open all the
  ## passive ports, however.
  networking.firewall = {
    allowedTCPPorts = [ 21 ];
    allowedTCPPortRanges = [
      {
        from = pasvMinPort;
        to = pasvMaxPort;
      }
    ];
  };

  ## The nginx module already handles the ACME certificate challenge very well,
  ## so we might as well use that. We do need the `ftp` user to be able to read
  ## the certificate, so we do a tiny trick for this.
  services.nginx.virtualHosts."ftp.niols.fr" = {
    forceSSL = true;
    enableACME = true;
    locations."/".return = "204";
  };
  security.acme.certs."ftp.niols.fr".group = "ftp-nginx";
  users.groups.ftp-nginx.members = [
    "ftp"
    "nginx"
  ];

  ## Create an actual user for Kerl, with a password, but prevent connection
  ## via SSH to them.
  users.users.kerl = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.ftp-password-kerl.path;
    home = "/hester/services/ftp/kerl";
  };
  services.openssh.settings.DenyUsers = [ "kerl" ];

  ## Password secret file for Kerl.
  age.secrets.ftp-password-kerl.file = "${secrets}/ftp-password-kerl.age";

  ## Home on Hester for Kerl.
  _common.hester.fileSystems = {
    ftp-kerl = {
      path = "/services/ftp/kerl";
      uid = "kerl";
      gid = "ftp";
    };
  };
}
