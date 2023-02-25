{ config, pkgs, ... }:

{
  imports = [ ];

  ############################################################################
  ## Boot
  ##
  ## TODO: experiment with the following
  ##
  ## boot.loader.grub.backgroundColor
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.backgroundColor
  ##
  ## boot.loader.grub.extraConfig
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.extraConfig
  ##
  ## boot.loader.grub.fontSize
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.fontSize
  ##
  ## boot.loader.grub.gfxmodeBios
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.gfxmodeBios
  ##
  ## boot.loader.grub.gfxmodeEfi
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.gfxmodeEfi
  ##
  ## boot.loader.grub.splashImage
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.splashImage
  ##
  ## boot.loader.grub.theme
  ## https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.grub.theme

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;
        version = 2;
        efiSupport = true;
        enableCryptodisk = true;

        ## The device on which the GRUB boot loader will be
        ## installed. The special value nodev means that a GRUB boot
        ## menu will be generated, but GRUB itself will not actually
        ## be installed. To install GRUB on multiple devices, use
        ## boot.loader.grub.devices.
        device = "nodev";

        ## FIXME: Attempt to use a Grub theme. cf:
        ## - Nix package: `legacyPackages.x86_64-linux.breeze-grub`
        ## - Nix package: `legacyPackages.x86_64-linux.nixos-grub2-theme`
        ## - https://fostips.com/boot-menu-modern-stylish-grub-themes/
        ## - https://github.com/vinceliuice/grub2-themes

        ## FIXME: to try
        ##
        ## Grub menu is painted really slowly on HiDPI, so we lower the
        ## resolution. Unfortunately, scaling to 1280x720 (keeping aspect
        ## ratio) doesn't seem to work, so we just pick another low one.
        ##
        ## Tried:
        ## - 1024x768 (works!)
        ## - 1280x800 (does not work)
        ## - 1280x720 (does not work)
        ## - 1280x960 (does not work)
        ## - 1400x900 (does not work)
        ##
        gfxmodeEfi = "1024x768";
        #gfxmodeBios = "1024x768";
      };
    };

    initrd.luks.devices = {
      crypt = {
        device = "/dev/nvme0n1p2";
        preLVM = true;
      };
    };
  };

  ############################################################################
  ## Fonts

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];

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
        "8.8.8.8" "8.8.4.4" ## Google
    ];
  };

  ############################################################################
  ## Time zone and internationalisation

  ## List all available timezones with:
  ##
  ##     timedatectl list-timezones
  ##
  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  ############################################################################
  ## X11 windowing system configuration

  services.xserver = import ./xserver.nix { inherit pkgs; };

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

  services.udev = import ./udev.nix;

  ## Visit http://127.0.0.1:8384/ to check that it works.
  services.syncthing = import ./syncthing.nix;

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
