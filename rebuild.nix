{
  writeShellApplication,
  git,
  nix-output-monitor,
  home-manager,
}:

writeShellApplication {
  name = "rebuild";
  runtimeInputs = [
    git
    nix-output-monitor
    home-manager
  ];
  excludeShellChecks = [ "SC2016" ];
  text = ''
    set -euC

    usage () {
      cat <<EOF
    Usage: $0 [option [option ...]] [action]

    [action] can be one of:

        boot      make the configuration the default boot entry
        switch    make the configuration the default boot entry, and activate it (default)

    [option] can be one of:

        --dirty, -d           proceed even if the repository is dirty
        --no-dirty            do not proceed if the repository is dirty (default)
        --update, -u          pull the configuration before rebuilding
        --no-update           do not pull the configuration before rebuilding (default)
        --home-profile <s>    run a Home Manager installation with this profile (default: autodetect)
        --help, -h            show this help and exit
    EOF
    }

    action=switch
    update=false
    proceed_if_dirty=false
    home_profile=

    while [ $# -gt 0 ]; do
      case $1 in
        boot) action=boot ;;
        switch) action=switch ;;
        --update|-u) update=true ;;
        --no-update) update=false ;;
        --dirty|-d) proceed_if_dirty=true ;;
        --no-dirty) proceed_if_dirty=false ;;
        --home-profile) shift; home_profile=$1 ;;
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

    if [ -z "$home_profile" ] && [ -e ~/.config/nixos/.home-profile ]; then
      home_profile=$(cat ~/.config/nixos/.home-profile)
      printf 'Detected a Home Manager installation; will use home profile `%s`\n' "$home_profile"
    fi
    readonly home_profile

    if [ "$action" = boot ] && [ -n "$home_profile" ]; then
      printf '\e[31mError: cannot use action %s with a home profile.\n' "$action"
      exit 2
    fi

    if ! [ -e ~/.config/nixos ]; then
      mkdir -p ~/.config
      printf 'The repository could not be found, cloning...\n'
      git clone git@github.com:niols/nixos-config.git ~/.config/nixos
      printf 'done.\n'
    fi

    cd ~/.config/nixos

    current_branch=$(git branch --show-current)
    readonly current_branch
    if [ "$current_branch" != main ]; then
      printf '\e[36mNote: the current branch is not `main` but `%s`\n' "$current_branch"
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
      printf 'Updating the configuration repository...\n'
      git pull origin "$current_branch" --ff-only
      printf 'done.\n'
    fi

    if [ -z "$home_profile" ]; then
      printf 'Rebuilding NixOS configuration...\n'
      if ! [ -e /etc/NIXOS ]; then
        printf '\e[36mThis does not look like a NixOS machine. Do you mean to run this script with --home-profile?\e[0m\n'
      fi
      sudo true
      sudo nixos-rebuild $action --flake ~/.config/nixos --builders '@/etc/nix/machines' |& nom
      printf 'done.\n'
    else
      printf 'Rebuilding Home configuration...\n'
      home-manager \
        --extra-experimental-features 'nix-command flakes' \
        switch --impure --flake ~/.config/nixos#"$home_profile" \
        |& nom
      echo "$home_profile" >| ~/.config/nixos/.home-profile
      printf  'done.\n'
    fi

    if $is_dirty; then
      printf '\e[36mNot adding a Git tag for the current generation,\n'
      printf 'because the working directory is dirty.\n\e[0m'

    else
      printf 'Adding a Git tag for the current generation...\n'
      hostname=$(hostname -s)
      if [ -z "$home_profile" ]; then
        output=$(nixos-rebuild list-generations --json | jq '.[] | select(.current == true)')
        if [ -z "$output" ]; then
          printf '\e[31mError: no current generation found.\n\e[0m'
          exit 2
        fi
        generation=$(echo "$output" | jq -r .generation)
        date=$(echo "$output" | jq -r .date | cut -d ' ' -f 1)
        nixosVersion=$(echo "$output" | jq -r .nixosVersion)
        tag=nixos-$hostname-gen-$generation
        description="NixOS configuration \`$hostname\` — generation $generation ($date - $nixosVersion)"
      else
        generation=$(home-manager generations | grep '(current)' | cut -d ' ' -f 5)
        if ! [[ "$generation" =~ ^[0-9]+$ ]]; then
          printf '\e[31mError: could not find the Home generation.\n\e[0m'
          exit 2
        fi
        date=$(date +'%Y-%m-%d')
        tag=home-$home_profile-on-$hostname-gen-$generation
        description="Home configuration \`$home_profile\` — generation $generation ($date)"
      fi
      if [ -n "$(git tag --list "$tag")" ]; then
        printf '\e[36mThe tag already exists. This means that you rebuilt something\n'
        printf 'that did not change the configuration at all. Tagging anyway...\n\e[0m'
        rebuild_number=2
        tag_with_rebuild=$tag-rebuild-$rebuild_number
        while [ -n "$(git tag --list "$tag_with_rebuild")" ]; do
          rebuild_number=$((rebuild_number + 1))
          tag_with_rebuild=$tag-rebuild-$rebuild_number
        done
        tag=$tag_with_rebuild
      fi
      printf 'Tagging as: %s\nwith description: %s\n' "$tag" "$description"
      git tag "$tag" -m "$description"
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
}
