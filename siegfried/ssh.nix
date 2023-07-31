_: {
  services = {
    openssh = {
      enable = true;
      ports = [ 22 2222 3000 9100 ];

      hostKeys = [
        {
          bits = 4096;
          path = "/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
        }
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };

  programs.mosh.enable = true;
}
