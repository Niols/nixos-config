{ config, ... }:

{
  ## Useful for servers, obviously, but also for laptops because we use Age and
  ## we want it to pick up on the SSH host keys. REVIEW: Maybe not on laptops,
  ## as we generate them manually?
  services.openssh.enable = true;

  services.openssh.hostKeys = [
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

  programs.mosh.enable = config.x_niols.isServer;
}
