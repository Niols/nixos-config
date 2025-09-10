{ pkgs, lib, ... }:

let
  inherit (lib) mkForce;

in
{
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
    '';
  };

  ## For using `nix-index` as the `command-not-found` hook, we need to disable
  ## that hook. FIXME: this and all the `nix-index` stuff should go in the same
  ## file.
  programs.command-not-found.enable = false;

  ############################################################################
  ## This value determines the NixOS release from which the default
  ## settings for stateful data, like file locations and database
  ## versions on your system were taken. It‘s perfectly fine and
  ## recommended to leave this value at the release version of the
  ## first install of this system.  Before changing this value read
  ## the documentation for this option (e.g. man configuration.nix or
  ## on https://nixos.org/nixos/options.html).
  system.stateVersion = mkForce "21.05"; # Did you read the comment?
  # ^ FIXME: unify with other system.stateVersion in _common.
}
