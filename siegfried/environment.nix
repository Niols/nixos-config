{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    emacs
    btop
    tmux
    wget
    git
    bat
    ripgrep
    fd
  ];
}
