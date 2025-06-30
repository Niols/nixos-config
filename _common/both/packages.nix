{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    emacs
    btop
    borgbackup
    tmux
    wget
    git
    bat
    ripgrep
    fd
  ];
}
