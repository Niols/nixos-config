{ pkgs, ... }:

{
  ## Allow a selected set of unfree packages for this list.
  nixpkgs.config.allowUnfreePredicate = (
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "discord"
      "slack"
      "steam"
      "steam-unwrapped"
      "teamspeak-client"
      "teamspeak-server"
      "unrar"
      "zoom"
    ]
  );

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

    ## Y
    yq
  ];
}
