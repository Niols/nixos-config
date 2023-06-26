{ config, secrets, ... }:

{
  ## The users' passwords must be set in this configuration and will be enforced
  ## at each configuration activation.
  users.mutableUsers = false;

  users.users.niols = {
    isNormalUser = true;
    extraGroups = [ "public" "wheel" ];

    passwordFile = config.age.secrets.siegfried-niols-password.path;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEElREJN0AC7lbp+5X204pQ5r030IbgCllsIxyU3iiKY niols@wallace"
    ];
  };

  age.secrets.siegfried-niols-password.file = "${secrets}/siegfried-niols-password.age";
}
