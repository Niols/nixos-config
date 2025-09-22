## FIXME: A file for everthing that does not have a good spot elsewhere. This
## should probably just be a file `laptop.nix` that imports everything else.

{ config, pkgs, ... }:

{
  niols-motd = {
    enable = true;
    hostname = config.x_niols.thisDevicesName;
    hostcolour = "green";
  };

  programs.weylus = {
    enable = true;
    openFirewall = true;
    users = [ "niols" ];
  };

  ############################################################################
  ## Fonts

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    google-fonts
  ];

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
  ## Bluetooth

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

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
}
