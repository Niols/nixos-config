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
        sudo nixos-rebuild boot --builders '@/etc/nix/machines' |& nom

        printf 'done.\nAdding a Git tag for the current generation...\n'
        output=$(nixos-rebuild list-generations --json | jq '.[] | select(.current == true)')
        if [ -z "$output" ]; then
          printf '\e[31mError: no current generation found.\n\e[0m'
          exit 2
        fi
        generation=$(echo "$output" | jq -r .generation)
        date=$(echo "$output" | jq -r .date | cut -d ' ' -f 1)
        nixosVersion=$(echo "$output" | jq -r .nixosVersion)
        git tag "$generation" -m "NixOS - Configuration $generation ($date - $nixosVersion)"

        printf 'done.\nPushing changes to remote...\n'
        git push --tags

        printf 'done.\nDo you wish to reboot? (y/N) '
        read -r answer
        if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
          printf 'Rebooting...\n'
          reboot
        else
          printf 'done.\n'
        fi
      '';
    })
  ];
}
