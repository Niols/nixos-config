{
  services.openssh = {
    enable = true;
    ## A bit overkill to enable SSH but that is the way to generate host keys.
    ## REVIEW: potentially, it could be disabled after the very first
    ## activation.

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
}
