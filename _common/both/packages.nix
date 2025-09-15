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
    bintools
    borgbackup
    btop

    ## C
    calc
    comma

    ## D
    dig

    ## E
    emacs
    entr

    ## F
    fd

    ## G
    git
    git-lfs

    ## H
    htop
    httpie

    ## J
    jq
    jless

    ## K
    killall

    ## N
    nix-output-monitor

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
    yamllint
    yq
  ];
}
