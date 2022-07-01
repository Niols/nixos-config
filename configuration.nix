{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./home-manager.nix
    <home-manager/nixos>
  ];

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

        ## FIXME: to try
        ##
        ## Grub menu is painted really slowly on HiDPI, so we lower the
        ## resolution. Unfortunately, scaling to 1280x720 (keeping aspect
        ## ratio) doesn't seem to work, so we just pick another low one.
        ##
        ## Tried:
        ## - 1280x800 (does not work)
	## - 1280x720 (does not work)
        ##
        gfxmodeEfi = "1280x960";
        gfxmodeBios = "1280x960";
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

  time.timeZone = "Europe/Amsterdam";
  # time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  ############################################################################
  ## X11 windowing system configuration

  services.xserver = {
    enable = true;

    ## Keymap: US International.
    ## FIXME: add non-breakable spaces on space bar.
    ## FIXME: add longer dashes somewhere.
    ## FIXME: what about three dots?
    layout = "us";
    xkbVariant = "intl";

    ## XFCE as desktop manager...
    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };

    ## ...with i3 as window manager.
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu i3status i3lock
        python39Packages.py3status ## wrapper around i3status
      ];
    };

    ## The display manager choses this combination.
    displayManager.defaultSession = "xfce+i3";

    ## Enable touchpad support. On the Lenovo X1 Carbon, the touchpad does not
    ## work so great, so we are trying workarounds as described in:
    ## https://github.com/NixOS/nixpkgs/issues/19022
    libinput.enable = true;
    synaptics.enable = false;
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

  users.users.niols = {
    isNormalUser = true;
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
    ];
  };

  ############################################################################
  ## Nix

  nix = {
    # settings.trusted-users = ["@wheel"];

    ## Tweag Remote Builder
    buildMachines = [ {
      hostName = "build01.tweag.io";
      maxJobs = 24;
      sshUser = "nix";
      sshKey = "/root/.ssh/id-tweag-builder";
      system = "x86_64-linux";
      supportedFeatures = [ "benchmark" "big-parallel" "kvm" ];
    } ];

    ## Required for as long as `nix flakes` are not available. FIXME:
    ## try removing this eventually?
    package = pkgs.nixFlakes;

    extraOptions = ''
      builders-use-substitutes = true

      ## Required to use the `nix` CLI and `nix search` in particular.
      experimental-features = nix-command flakes
    '';

    # ## IOHK Binary Cache
    # settings.substituters = [ "https://hydra.iohk.io" "https://iohk.cachix.org" ];
    # settings.trusted-public-keys = [
    #   "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    #   "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo="
    # ];

    # ## Garbage-collect automatically on a weekly basis; keep old
    # ## versions during 20 days.
    # settings.auto-optimise-store = true;
    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 20d";
    # };
  };

  ############################################################################
  ## Bashrc

  programs.bash.promptInit = builtins.readFile ./bash-prompt.sh;

  ############################################################################
  ## Extra `udev` rules.

  services.udev.extraRules = ''
## For Ledger devices; owned solely by `niols`.
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0000|0001|0002|0003|0004|0005|0006|0007|0008|0009|000a|000b|000c|000d|000e|000f|0010|0011|0012|0013|0014|0015|0016|0017|0018|0019|001a|001b|001c|001d|001e|001f|1000|1001|1002|1003|1004|1005|1006|1007|1008|1009|100a|100b|100c|100d|100e|100f|1010|1011|1012|1013|1014|1015|1016|1017|1018|1019|101a|101b|101c|101d|101e|101f|2000|2001|2002|2003|2004|2005|2006|2007|2008|2009|200a|200b|200c|200d|200e|200f|2010|2011|2012|2013|2014|2015|2016|2017|2018|2019|201a|201b|201c|201d|201e|201f|3000|3001|3002|3003|3004|3005|3006|3007|3008|3009|300a|300b|300c|300d|300e|300f|3010|3011|3012|3013|3014|3015|3016|3017|3018|3019|301a|301b|301c|301d|301e|301f|4000|4001|4002|4003|4004|4005|4006|4007|4008|4009|400a|400b|400c|400d|400e|400f|4010|4011|4012|4013|4014|4015|4016|4017|4018|4019|401a|401b|401c|401d|401e|401f|5000|5001|5002|5003|5004|5005|5006|5007|5008|5009|500a|500b|500c|500d|500e|500f|5010|5011|5012|5013|5014|5015|5016|5017|5018|5019|501a|501b|501c|501d|501e|501f", OWNER="niols", MODE="0600"
  '';

  ############################################################################
  ## Transparency

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
