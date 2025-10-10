{
  config,
  lib,
  keys,
  ...
}:

let
  inherit (lib)
    attrValues
    mkMerge
    mkIf
    mkOption
    types
    genAttrs
    ;
  inherit (lib.lists)
    optionals
    ;

  normalUsers =
    optionals config.x_niols.enableNiolsUser [ "niols" ]
    ++ optionals config.x_niols.enableWorkUser [ "work" ];
  normalUsersAndRoot = normalUsers ++ [ "root" ];

in
{
  options.x_niols = {
    enableNiolsUser = mkOption {
      description = ''
        Whether a `niols` user should be created. This is true by default on
        personal machine, and false by default on servers.
      '';
      default = !config.x_niols.isServer;
      type = types.bool;
    };

    enableWorkUser = mkOption {
      description = ''
        Wether a `work` user should be created.
      '';
      default = false;
      type = types.bool;
    };
  };

  config = mkMerge [
    ## Create the normal users and given them root access.
    {
      users.users = genAttrs normalUsers (_: {
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # for `sudo`
      });
    }

    ## Make each system activation forcefully replace the current status of
    ## users, and have a hardcoded user password for each user (including
    ## `root`) on each machine.
    {
      users.mutableUsers = false;
      users.users = genAttrs normalUsersAndRoot (username: {
        hashedPasswordFile =
          config.age.secrets."password-${config.x_niols.thisMachinesName}-${username}".path;
      });
    }

    ## Laptops-specific configuration
    (mkIf (!config.x_niols.isServer) {
      users.users = genAttrs normalUsers (_: {
        ## NOTE: groups in `users.*.extraGroups` are not created if they do not
        ## exist. They must be created by other means.
        ##
        ## `adbusers` is created when `programs.adb.enable = true` is set
        ## somewhere. (FIXME: Does this setting also create `plugdev`? Not
        ## sure.)
        ##
        extraGroups = [
          "adbusers" # for `adb` and `fastboot`
          "docker" # for Docker
          "networkmanager" # for NetworkManager
          #"plugdev" # see below
        ];

        ## NOTE: Not great, but necessary for the `.face`, and will allow `niols`
        ## and `work` to see each other's files if necessary. This works because
        ## this is a one-person laptop.
        ## cf https://github.com/NixOS/nixpkgs/issues/73976
        homeMode = "755";
      });

      ## `plugdev` is a classic group for USB devices; it will be used in `udev`
      ## rules. It needs to be explicitly created first.
      users.groups.plugdev.members = normalUsers;
    })

    ## On servers, normal users and `root` are accessible via SSH using Niols's
    ## keys or the additional GHA deployment key.
    (mkIf config.x_niols.isServer {
      users.users = genAttrs normalUsersAndRoot (_: {
        openssh.authorizedKeys.keys = attrValues keys.niols ++ [ keys.github-actions ];
      });
    })
  ];
}
