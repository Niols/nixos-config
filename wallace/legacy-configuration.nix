{ pkgs, ... }:

{
  ############################################################################
  ## Fonts

  fonts.packages = with pkgs;
    [ (nerdfonts.override { fonts = [ "FiraCode" ]; }) ];

  ############################################################################
  ## Networking
  ##
  ## The global useDHCP flag is deprecated, therefore explicitly set
  ## to false here. wPer-interface useDHCP will be mandatory in the
  ## future, so this generated config replicates the default
  ## behaviour.

  networking = {
    hostName = "wallace";

    useDHCP = false;
    interfaces.wlp0s20f3.useDHCP = true;

    networkmanager.enable = true;

    nameservers = [
      # "1.1.1.1" "1.0.0.1" ## Cloudflare
      "8.8.8.8"
      "8.8.4.4" # # Google
    ];
  };

  ############################################################################
  ## GNOME Stuff

  services.gnome.gnome-keyring.enable = true;

  ## When using Nautilus without GNOME, you may need to enable the
  ## GVfs service in order for Nautilus to work properly. If GVfs is
  ## not available, you may see errors such as "Sorry, could not
  ## display all the contents of “trash:///”: Operation not supported"
  ## when trying to open the trash folder, or be unable to access
  ## network filesystems.
  ##
  services.gvfs.enable = true;

  ############################################################################
  ## Enable CUPS to print documents.

  services.printing.enable = true;

  services.acpid.enable = true;

  ## Start GPG agent with SSH support (note: incompatible with
  ## ssh.startAgent)
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  # programs.ssh.startAgent = true;

  ############################################################################
  ## Virtualisation

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;
  # virtualisation.virtualbox.host.enable = true;

  ############################################################################
  ## Sound

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  ############################################################################
  ## Bluetooth

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

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

  ############################################################################
  ## Nix

  nix = import ./nix.nix;

  ############################################################################
  ## Android setup

  ## As of 26 October 2022, `android-tools` is broken, so we're disabling it.
  # programs.adb.enable = true;

  ############################################################################
  ## Shells

  environment.shellAliases = {
    cal = "cal --monday";
    ls = "ls --quoting-style=literal --color=auto";
  };

  programs.bash = {
    interactiveShellInit = ''
      ## If OPAM is available on the system and it has been initialised, then we
      ## set it up for this Shell.
      ##
      if command -v opam >/dev/null; then
        if opam switch >/dev/null 2>&1; then
          eval "$(opam env)"
        fi
      fi

      ## If `direnv` is available on the system, then we set it up for
      ## this Shell. Also, we make it completely quiet (the status
      ## line will inform us of direnv's presence). These lines should
      ## appear after all Shell extensions that manipulate the prompt.
      ##
      if command -v direnv >/dev/null; then
        eval "$(direnv hook bash)"
        export DIRENV_LOG_FORMAT=
      fi
    '';
  };

  ## For using `nix-index` as the `command-not-found` hook, we need to disable
  ## that hook. FIXME: this and all the `nix-index` stuff should go in the same
  ## file.
  programs.command-not-found.enable = false;

  ############################################################################
  ## Background & Transparency

  services.picom.enable = true;

  ############################################################################
  ## This value determines the NixOS release from which the default
  ## settings for stateful data, like file locations and database
  ## versions on your system were taken. It‘s perfectly fine and
  ## recommended to leave this value at the release version of the
  ## first install of this system.  Before changing this value read
  ## the documentation for this option (e.g. man configuration.nix or
  ## on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
