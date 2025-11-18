{ pkgs, ... }:

{
  imports = [
    ./autorandr.nix
    ./hardware.nix
    ./network.nix
    ./syncthing.nix
    ./timezone.nix
    ./udev.nix
    ./xserver
  ];

  programs.localsend.enable = true;

  ############################################################################
  ## Fonts

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    google-fonts
  ];

  ############################################################################
  ## GNOME Stuff

  ## When using Nautilus without GNOME, you may need to enable the
  ## GVfs service in order for Nautilus to work properly. If GVfs is
  ## not available, you may see errors such as "Sorry, could not
  ## display all the contents of “trash:///”: Operation not supported"
  ## when trying to open the trash folder, or be unable to access
  ## network filesystems.
  ##
  services.gvfs.enable = true;

  ## Used by eg. Nextcloud to remember its tokens from one run to the next.
  ## Ideally, this would be in Home. Home Manager has `services.gnome-keyring`,
  ## but it doesn't work for me, complaining about access to its control file.
  ##
  services.gnome.gnome-keyring.enable = true;

  ############################################################################
  ## Enable CUPS to print documents.

  services.printing.enable = true;

  services.acpid.enable = true;

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
  ## Steam
  ##
  ## We would rather put those options in HM, but they just don't exist, as
  ## Steam needs to touch many things in the environment to function.

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true; # support for controllers
}
