{ config, lib, ... }:

let
  inherit (lib) mkOption types genAttrs;

  users = [ "niols" ] ++ (if config.x_niols.enableWorkUser then [ "work" ] else [ ]);

in
{
  options.x_niols.enableWorkUser = mkOption {
    default = false;
    type = types.bool;
  };

  ############################################################################
  ## User account.

  ## - `adbusers` are necessary for `adb` & `fastboot`.
  ## - `docker` for Docker
  ## - `networkmanager` for NetworkManager
  ## - `plugdev` is a classic group for USB devices
  ## - `wheel` for `sudo`

  ## NOTE: groups in `users.*.extraGroups` are not created if they do not exist.
  ## They must be created by other means.
  ##
  ## - `adbusers` is created when `programs.adb.enable = true` is set somewhere.
  ##   (FIXME: Does this setting also create `plugdev`? Not sure.)
  ##
  ## - `plugdev` needs to be explicitly created in `users.groups`.

  config = {
    users.users = genAttrs users (_user: {
      isNormalUser = true;
      extraGroups = [
        "adbusers"
        "docker"
        "networkmanager"
        #"plugdev"
        "wheel"
      ];

      ## NOTE: Not great, but necessary for the `.face`, and will allow `niols`
      ## and `work` to see each other's files if necessary. This works because
      ## this is a one-person laptop.
      ## cf https://github.com/NixOS/nixpkgs/issues/73976
      homeMode = "755";
    });

    users.groups.plugdev.members = users;
  };
}
