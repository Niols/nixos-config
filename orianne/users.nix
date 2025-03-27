{
  config,
  keys,
  secrets,
  ...
}:

let
  inherit (builtins) attrValues;
in

{
  ## Make each system activation forcefully replace the current status of users.
  users.mutableUsers = false;

  users.users.niols = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = attrValues keys.niols;
    hashedPasswordFile = config.age.secrets.password-orianne-niols.path;
  };

  users.users.root.openssh.authorizedKeys.keys = with keys; [
    niols.wallace
    github-actions.deploy-orianne
  ];

  ## It can be pratical for the users to have a cron service running.
  services.cron.enable = true;
}
