{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ emacs htop tmux wget git bat ];
}
