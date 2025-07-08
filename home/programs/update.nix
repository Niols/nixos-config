{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "update";
      runtimeInputs = with pkgs; [
        git
        nix-output-monitor
      ];
      text = ''
        set -euC

        cd /etc/nixos

        if [ "$(git branch --show-current)" != main ]; then
          printf '\e[31mError: not on main branch.\n\e[0m'
          exit 2
        fi

        if [ -n "$(git status --porcelain)" ]; then
          printf '\e[31mError: working directory is not clean.\n\e[0m'
          exit 2
        fi

        printf 'Updating NixOS configuration...\n'
        git pull --ff-only

        printf 'done.\nUpgrading NixOS configuration...\n'
        sudo true
        sudo nixos-rebuild switch --builders '@/etc/nix/machines' |& nom
        printf 'done.\n'
      '';
    })
  ];
}
