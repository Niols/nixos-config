{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ############################################################################
  ## Time zone and internationalisation
  ##
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  ############################################################################
  ## Networking
  ##
  ## The global useDHCP flag is deprecated, therefore explicitly set to false
  ## here. Per-interface useDHCP will be mandatory in the future, so this
  ## generated config replicates the default behaviour.
  ##
  networking = {
    hostName = "gromit";

    useDHCP = false;
    interfaces.enp0s31f6.useDHCP = true;
    interfaces.wlp0s20f3.useDHCP = true;

    networkmanager.enable = true;
  };

  ############################################################################
  ## Nix

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  ############################################################################
  ## Bluetooth
  ##
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  ############################################################################
  ## X11 windowing system configuration
  ##
  services.xserver = {
    enable = true;

    ## Keymap: US international.
    layout = "us";
    xkbVariant = "intl";

    ## Touchpad support (enabled default in most desktopManager).
    libinput.enable = true;

    ## XFCE as desktop manager...
    desktopManager.xterm.enable = false;
    desktopManager.xfce = {
      enable = true;
      noDesktop = true;
      enableXfwm = false;
    };

    ## with i3 as window manager.
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        python39Packages.py3status ## wrapper around i3status
      ];
    };

    ## The display manager choses this combination.
    displayManager.defaultSession = "xfce+i3";
  };

  ############################################################################
  ## Fix for Nautilus. cf:
  ##
  ## When using Nautilus without GNOME, you may need to enable the GVfs
  ## service in order for Nautilus to work properly. If GVfs is not available,
  ## you may see errors such as "Sorry, could not display all the contents of
  ## “trash:///”: Operation not supported" when trying to open the trash
  ## folder, or be unable to access network filesystems.
  ##
  services.gvfs.enable = true;

  ############################################################################
  ## Enable CUPS to print documents.
  ##
  services.printing.enable = true;

  ############################################################################
  ## Sound
  ##
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  ############################################################################
  ## User account.
  ##
  users.users.niols = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  ############################################################################
  ## System packages

  ## FIXME: Skype for Linux, Zoom, Telegram
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "discord"
    "skypeforlinux"
    "slack"
    "steam-original"
    "unrar"
    "zoom"
  ];

  environment.systemPackages = with pkgs; [
    ## A
    arandr

    ## C
    chromium

    ## D
    discord

    ## E
    element-desktop
    emacs
    evince

    ## F
    firefox

    ## G
    gimp
    git
    gnumake

    ## J
    jq

    ## K
    keepassxc

    ## L
    ledger-live-desktop
    libreoffice

    ## M
    mosh

    ## N
    gnome.nautilus
    nextcloud-client

    ## O
    opam

    ## P
    pavucontrol

    ## R
    racket

    ## S
    signal-desktop
    skypeforlinux
    slack
    steam-run

    ## T
    texlive.combined.scheme-full
    thunderbird

    ## U
    unrar
    unzip

    ## V
    vlc

    ## W
    wget

    ## Y
    youtube-dl

    ## Z
    zoom-us
  ];

  ## Some programs need SUID wrappers, can be configured further or are
  ## started in user sessions.
  ##
  #programs.mtr.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  ############################################################################
  ## Docker

  virtualisation.docker.enable = true;

  ############################################################################
  ## udev rules for connecting to Ledger devices

  services.udev.extraRules = ''
## Ledger Nano S Plus
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="5011", OWNER="niols"
  '';

  ############################################################################
  ## Home Manager

  home-manager.users.niols = { pkgs, ... }: {
    programs = {
      bash.enable = true;

      git = {
        enable = true;
	ignores = [ "*~" "*#" ];

        ## Require to sign by default, but give a useless key, forcing
        ## myself to setup the key correctly in the future.
	signing.key = "YOU NEED TO EXPLICITLY SETUP THE KEY";
	signing.signByDefault = true;

        ## Change of personality depending on the location in the file
        ## tree. This only switches between personal and profesionnal.
	includes = [
	  {
	    condition = "gitdir:~/git/perso/**";
	    contents.user = {
	      name = "Niols";
	      email = "niols@niols.fr";
	      signingKey = "2EFDA2F3E796FF05ECBB3D110B4EB01A5527EA54";
            };
	  }
	  {
	    condition = "gitdir:~/git/tweag/**";
	    contents.user = {
	      name = "Nicolas “Niols” Jeannerod";
	      email = "nicolas.jeannerod@tweag.io";
	      signingKey = "71CBB1B508F0E85DE8E5B5E735DB9EC8886E1CB8";
	    };
	  }
	  {
	    condition = "gitdir:~/git/hachi/**";
	    contents.user = {
	      name = "Nicolas “Niols” Jeannerod";
	      email = "nicolas.jeannerod@tweag.io";
	      signingKey = "71CBB1B508F0E85DE8E5B5E735DB9EC8886E1CB8";
	    };
	  }
	];

        extraConfig.url = {
	  "ssh://git@github.com/" = { insteadOf = "https://github.com/"; };
	};
      };
    };
  };

  ############################################################################
  ## This value determines the NixOS release from which the default
  ## settings for stateful data, like file locations and database versions
  ## on your system were taken. It‘s perfectly fine and recommended to leave
  ## this value at the release version of the first install of this system.
  ## Before changing this value read the documentation for this option
  ## (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
