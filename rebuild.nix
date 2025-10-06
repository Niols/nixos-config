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

    # shellcheck disable=SC2059
    info () { fmt=$1; shift; printf "\e[37m[INF] $fmt\e[0m\n" "$@"; }
    # shellcheck disable=SC2059
    warning () { fmt=$1; shift; printf "\e[33m[WRN] $fmt\e[0m\n" "$@"; }
    # shellcheck disable=SC2059
    error () { fmt=$1; shift; printf "\e[31m[ERR] $fmt\e[0m\n" "$@"; }
    # shellcheck disable=SC2059,SC2229
    ask () { var=$1; shift; fmt=$1; shift; printf "\e[37m\e[1m[ASK]\e[22m $fmt\e[0m " "$@"; read -r "$var"; }

    usage () {
      cat <<EOF
    Usage: $0 [option [option ...]] [action]

    [action] can be one of:

        boot      make the configuration the default boot entry
        switch    make the configuration the default boot entry, and activate it (default)

    [option] can be one of:

        --dirty, -d           proceed even if the repository is dirty (default: ask)
        --main, -m            checkout main if on another branch (default: ask)
        --stay, -s            stay on the branch if it is not main (default: ask)
        --update, -u          pull the configuration before rebuilding (default: do not update)
        --home-profile <s>    run a Home Manager installation with this profile (default: autodetect)
        --help, -h            show this help and exit
    EOF
    }

    action=switch
    update=false
    action_if_dirty=ask
    action_if_not_main=ask
    home_profile=

    while [ $# -gt 0 ]; do
      case $1 in
        boot) action=boot ;;
        switch) action=switch ;;
        --dirty|-d) action_if_dirty=true ;;
        --main|-m) action_if_not_main=checkout ;;
        --stay|-s) action_if_not_main=stay ;;
        --update|-u) update=true ;;
        --home-profile) shift; home_profile=$1 ;;
        --help|-h) usage; exit 1 ;;
        *) error 'Unexpected argument: %s\n' "$1"; usage; exit 2 ;;
      esac
      shift
    done

    readonly action
    readonly update

    if [ -z "$home_profile" ] && [ -e ~/.config/nixos/.home-profile ]; then
      home_profile=$(cat ~/.config/nixos/.home-profile)
      info 'Detected a Home Manager installation; will use home profile `%s`.' "$home_profile"
    fi
    readonly home_profile

    if [ "$action" = boot ] && [ -n "$home_profile" ]; then
      error 'Cannot use action %s with a home profile.' "$action"
      exit 2
    fi

    if ! [ -e ~/.config/nixos ]; then
      mkdir -p ~/.config
      info 'The repository could not be found, cloning...'
      git clone git@github.com:niols/nixos-config.git ~/.config/nixos
      info 'done.'
    fi

    cd ~/.config/nixos

    if [ -n "$(git status --porcelain)" ]; then is_dirty=true; else is_dirty=false; fi
    readonly is_dirty
    if $is_dirty; then
      warning 'The working directory is dirty.'
      if [ $action_if_dirty = ask ]; then
        ask response 'Do you want to \e[1m[p]\e[22mroceed anyway or \e[1m[a]\e[22mbort?'
        # shellcheck disable=SC2154
        case $response in
          p)
            info 'You can also pass the --dirty argument to do this automatically.'
            action_if_dirty=proceed
            ;;
          a)
            action_if_dirty=abort
            ;;
          *)
            error 'Unexpected response: `%s`.' "$response"
            exit 2
        esac
      fi
      case $action_if_dirty in
        proceed)
          info 'Proceeding. Some functionalities, such as tagging, will not be available.'
          ;;
        abort)
          info 'Aborting.'
          exit 2
          ;;
        *)
          error 'Unexpected action if the repository is dirty: `%s`.' "$action_if_dirty"
          exit 3
      esac
    fi

    current_branch=$(git branch --show-current)
    readonly current_branch
    if [ "$current_branch" != main ]; then
      warning 'The current branch is not `main` but `%s`.' "$current_branch"
      if [ $action_if_not_main = ask ]; then
        ask response 'Do you want to \e[1m[c]\e[22mheckout `main`, \e[1m[s]\e[22mtay on `%s`, or \e[1m[a]\e[22mbort?' "$current_branch"
        # shellcheck disable=SC2154
        case $response in
          c)
            info 'You can also pass the --main argument to do this automatically.'
            action_if_not_main=checkout
            ;;
          s)
            info 'You can also pass the --stay argument to do this automatically.'
            action_if_not_main=stay
            ;;
          a)
            action_if_not_main=abort
            ;;
          *)
            error 'Unexpected response: `%s`.' "$response"
            exit 2
        esac
      fi
      case $action_if_not_main in
        checkout)
          if $is_dirty; then
            error 'Cannot checkout `main` when working directory is dirty.'
            exit 2
          else
            info 'Checking out `main`...'
            git checkout main
            info 'done.'
          fi
          ;;
        stay)
          info 'This script will only pull from and push to `%s`.' "$current_branch"
          ;;
        abort)
          info 'Aborting.'
          exit 2
          ;;
        *)
          error 'Unexpected action if the branch is not main: `%s`.' "$action_if_not_main"
          exit 3
      esac
    fi

    if $update; then
      if $is_dirty; then
        error 'Cannot update when working directory is dirty.'
        exit 2
      fi
      info 'Updating the configuration repository...'
      git pull --ff-only
      info 'done.'
    fi

    if [ -z "$home_profile" ]; then
      info 'Rebuilding NixOS configuration...'
      if ! [ -e /etc/NIXOS ]; then
        warning 'This does not look like a NixOS machine. Do you mean to run this script with --home-profile?'
      fi
      sudo true
      sudo nixos-rebuild $action --flake ~/.config/nixos --builders '@/etc/nix/machines' |& nom
      info 'done.'
    else
      info 'Rebuilding Home configuration...'
      home-manager \
        --extra-experimental-features 'nix-command flakes' \
        switch --impure --flake ~/.config/nixos#"$home_profile" \
        |& nom
      echo "$home_profile" >| ~/.config/nixos/.home-profile
      info 'done.'
    fi

    if $is_dirty; then
      info 'Not adding a Git tag for the current generation, because the working directory is dirty.'

    else
      info 'Adding a Git tag for the current generation...'
      hostname=$(hostname -s)
      if [ -z "$home_profile" ]; then
        output=$(nixos-rebuild list-generations --json | jq '.[] | select(.current == true)')
        if [ -z "$output" ]; then
          error 'No current generation found.'
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
          error 'Could not find the Home generation.'
          exit 2
        fi
        date=$(date +'%Y-%m-%d')
        tag=home-$home_profile-on-$hostname-gen-$generation
        description="Home configuration \`$home_profile\` on \`$hostname\` — generation $generation ($date)"
      fi
      if [ -n "$(git tag --list "$tag")" ]; then
        info 'The tag already exists. This means that you rebuilt something that did not change the configuration at all. Tagging anyway...'
        rebuild_number=2
        tag_with_rebuild=$tag-rebuild-$rebuild_number
        while [ -n "$(git tag --list "$tag_with_rebuild")" ]; do
          rebuild_number=$((rebuild_number + 1))
          tag_with_rebuild=$tag-rebuild-$rebuild_number
        done
        tag=$tag_with_rebuild
      fi
      info 'Tagging as: %s\nwith description: %s.' "$tag" "$description"
      git tag "$tag" -m "$description"
      info 'done.\nPushing changes to remote...'
      git push --tags
      info 'done.'
    fi

    if [ "$action" != switch ]; then
      ask answer 'Do you wish to reboot? (y/N)'
      # shellcheck disable=SC2154
      if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
        info 'Rebooting...'
        reboot
      fi
    fi

    info 'All done!'
  '';
}
