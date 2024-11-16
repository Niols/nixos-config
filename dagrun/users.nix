{ config, secrets, ... }:

{
  ## Make each system activation forcefully replace the current status of users.
  users.mutableUsers = false;

  users.users.niols = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEElREJN0AC7lbp+5X204pQ5r030IbgCllsIxyU3iiKY niols@wallace"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOwbbryqtVcJgJ/kgIFyDa8FQaWEPK/dsCV0yYdsZNBy niols@philippe"
    ];
    hashedPasswordFile = config.age.secrets.password-niols.path;
  };

  age.secrets.password-niols = {
    file = "${secrets}/password-dagrun-niols.age";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEElREJN0AC7lbp+5X204pQ5r030IbgCllsIxyU3iiKY niols@wallace"
  ];

  ## It can be pratical for the users to have a cron service running.
  services.cron.enable = true;
}
