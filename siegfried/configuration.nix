{ pkgs, ... }:

{
  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  environment.systemPackages = with pkgs; [ emacs htop tmux wget git bat ];
}
