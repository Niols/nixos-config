{ pkgs, ... }:

{
  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  environment.systemPackages = with pkgs; [ emacs htop tmux wget git bat ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.ports = [ 22 2222 3000 9100 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
