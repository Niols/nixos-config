{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "rebuild";
      runtimeInputs = with pkgs; [
        git
        nix-output-monitor
      ];
      text = ''
        set -euC

        usage () {
          cat <<EOF
        Usage: $0 [option [option ...]] [action]

        [action] can be one of:

            boot      make the configuration the default boot entry
            switch    make the configuration the default boot entry, and activate it (default)

        [option] can be one of:

            --dirty, -d     proceed even if the repository is dirty
            --no-dirty      do not proceed if the repository is dirty (default)
            --update, -u    pull the configuration before rebuilding
            --no-update     do not pull the configuration before rebuilding (default)
            --help, -h      show this help and exit
        EOF
        }

        action=switch
        update=false
        proceed_if_dirty=false

        while [ $# -gt 0 ]; do
          case $1 in
            boot) action=boot ;;
            switch) action=switch ;;
            --update|-u) update=true ;;
            --no-update) update=false ;;
            --dirty|-d) proceed_if_dirty=true ;;
            --no-dirty) proceed_if_dirty=false ;;
            --help|-h) usage; exit 1 ;;
            *) printf 'Unexpected argument: %s\n\n' "$1"; usage; exit 2 ;;
          esac
          shift
        done

        if $update && $proceed_if_dirty; then
          printf '\e[31mError: cannot use --update and --dirty\n'
          exit 2
        fi

        readonly action
        readonly update
        readonly proceed_if_dirty

        cd ~/.config/nixos

        current_branch=$(git branch --show-current)
        readonly current_branch
        if [ "$current_branch" != main ]; then
          printf '\e[36mNote: the current branch is not main but %s\n' "$current_branch"
          printf 'This script will only pull from and push to that branch.\n\e[0m'
        fi

        if [ -n "$(git status --porcelain)" ]; then is_dirty=true; else is_dirty=false; fi
        readonly is_dirty
        if $is_dirty && ! $proceed_if_dirty; then
          printf '\e[31mError: working directory is dirty.\n\e[0m'
          printf 'You may want to pass the --dirty argument.\n'
          exit 2
        fi

        if $update; then
          printf 'Updating NixOS configuration...\n'
          git pull origin "$current_branch" --ff-only
          printf 'done.\n'
        fi

        printf 'Rebuilding NixOS configuration...\n'
        sudo true
        sudo nixos-rebuild $action --builders '@/etc/nix/machines' |& nom
        printf 'done.\n'

        if $is_dirty; then
          printf '\e[36mNot adding a Git tag for the current generation,\n'
          printf 'because the working directory is dirty.\n\e[0m'

        else
          printf 'Adding a Git tag for the current generation...\n'
          hostname=$(hostname -s)
          output=$(nixos-rebuild list-generations --json | jq '.[] | select(.current == true)')
          if [ -z "$output" ]; then
            printf '\e[31mError: no current generation found.\n\e[0m'
            exit 2
          fi
          generation=$(echo "$output" | jq -r .generation)
          date=$(echo "$output" | jq -r .date | cut -d ' ' -f 1)
          nixosVersion=$(echo "$output" | jq -r .nixosVersion)
          tag=$hostname-$generation
          if [ -n "$(git tag --list "$tag")" ]; then
            printf '\e[36mThe tag already exists. This means that you rebuilt something\n'
            printf 'that did not change the configuration at all. Tagging anyway...\n\e[0m'
            offset=2
            while [ -n "$(git tag --list "$tag-$offset")" ]; do
              offset=$((offset + 1))
            done
            tag=$tag-$offset
          fi
          printf 'Tagging as: %s\n' "$tag"
          git tag "$tag" -m "$hostname — Configuration $generation ($date - $nixosVersion)"
          printf 'done.\nPushing changes to remote...\n'
          git push --tags
          printf 'done.\n'
        fi

        if [ "$action" != switch ]; then
          printf 'Do you wish to reboot? (y/N) '
          read -r answer
          if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
            printf 'Rebooting...\n'
            reboot
          else
            printf 'done.\n'
          fi
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "update";
      text = ''
        printf 'Running: rebuild boot --update\n'
        exec rebuild boot --update
      '';
    })
  ];
}
