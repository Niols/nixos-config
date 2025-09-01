{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ## B
    bat
    bc
    borgbackup
    btop

    ## C
    calc

    ## E
    emacs

    ## F
    fd

    ## G
    git
    git-lfs

    ## H
    htop

    ## J
    jq

    ## R
    ripgrep

    ## T
    tmux

    ## U
    unrar
    unzip

    ## W
    wget
  ];
}
