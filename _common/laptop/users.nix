{
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

  users = {
    users.niols = {
      isNormalUser = true;
      extraGroups = [
        "adbusers"
        "docker"
        "networkmanager"
        #"plugdev"
        "wheel"
      ];

      ## NOTE: Not great, but necessary for the `.face`.
      ## cf https://github.com/NixOS/nixpkgs/issues/73976
      homeMode = "755";
    };

    groups.plugdev.members = [ "niols" ];
  };
}
