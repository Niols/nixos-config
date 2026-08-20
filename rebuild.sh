set -euC

## ============================== [ Constants ] ============================== ##

github_repo=niols/nixos-config
local_repo=~/.config/nixos
main_branch=main

readonly github_repo local_repo main_branch

## ========================== [ Loggers & helpers ] ========================== ##

# shellcheck disable=SC2059
info () { fmt=$1; shift; printf "\e[37m[INF] $fmt\e[0m\n" "$@"; }
# shellcheck disable=SC2059
warning () { fmt=$1; shift; printf "\e[33m\e[1m[WRN] $fmt\e[0m\n" "$@"; }
# shellcheck disable=SC2059
error () { fmt=$1; shift; printf "\e[31m\e[1m[ERR] $fmt\e[0m\n" "$@"; }
# shellcheck disable=SC2059,SC2229
ask () { var=$1; shift; fmt=$1; shift; printf "\e[37m\e[1m[ASK]\e[22m $fmt\e[0m " "$@"; read -r "$var"; }

## ======================== [ Command line parsing ] ========================= ##

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
    --target <s>, -t      install and deploy a NixOS configuration for this machine (default: current machine)
    --dry-run             do not actually build or deploy anything
    --help, -h            show this help and exit
EOF
}

parse_cli ()
{
    action=switch
    update=false
    action_if_dirty=ask
    action_if_not_main=ask
    home_profile=
    target=
    dry_run=false

    while [ $# -gt 0 ]; do
        case $1 in
            boot) action=boot ;;
            switch) action=switch ;;
            --dirty|-d) action_if_dirty=proceed ;;
            --main|-m) action_if_not_main=checkout ;;
            --stay|-s) action_if_not_main=stay ;;
            --update|-u) update=true ;;
            --home-profile) shift; home_profile=$1 ;;
            --target|-t) shift; target=$1 ;;
            --dry-run) dry_run=true ;;
            --help|-h) usage; exit 1 ;;
            *) error 'Unexpected argument: %s\n' "$1"; usage; exit 2 ;;
        esac
        shift
    done

    readonly action
    readonly update
    readonly target
    readonly dry_run

    if [ -z "$home_profile" ] && [ -e "$local_repo"/.home-profile ]; then
        home_profile=$(cat "$local_repo"/.home-profile)
        info 'Detected a Home Manager installation; will use home profile `%s`.' "$home_profile"
    fi
    readonly home_profile

    if [ -n "$target" ] && [ -n "$home_profile" ]; then
        error 'Cannot use --target with a home profile.'
        exit 2
    fi

    if [ "$action" = boot ] && [ -n "$home_profile" ]; then
        error 'Cannot use action %s with a home profile.' "$action"
        exit 2
    fi
}

run () {
    printf '\e[36m\e[1m[RUN] %s\e[0m\n' "$*"
    if ! $dry_run; then "$@"; fi
}

## ===================== [ Set up the local repository ] ===================== ##

repo_setup ()
{
    if ! [ -e "$local_repo" ]; then
        mkdir -p "$(dirname "$local_repo")"
        info 'The repository could not be found, cloning...'
        run git clone git@github.com:"$github_repo".git "$local_repo"
        info 'done.'
    fi

    cd "$local_repo"
}

## ================== [ Check if the repository is dirty ] =================== ##

repo_check_dirty ()
{
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
}

## ======================= [ Check the branch/commit ] ======================= ##

get_current_branch () { git branch --show-current; }
get_current_commit () { git log --max-count=1 --format=%h; }

repo_check_branch_commit ()
{
    current_branch=$(get_current_branch)
    current_commit=$(get_current_commit)
    readonly current_branch current_commit

    if [ "$current_branch" != "$main_branch" ]; then
        if [ -n "$current_branch" ]; then
            warning 'The current branch is not `%s` but `%s`.' "$main_branch" "$current_branch"
        else
            warning 'The repository is in a detached HEAD state.'
        fi

        if [ $action_if_not_main = ask ]; then
            [ -n "$current_branch" ] && on_current_branch=$(printf 'on `%s`' "$current_branch") || on_current_branch=detached
            ask response 'Do you want to \e[1m[c]\e[22mheckout `%s`, \e[1m[s]\e[22mtay %s, or \e[1m[a]\e[22mbort?' "$main_branch" "$on_current_branch"
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
                    error 'Cannot checkout `%s` when working directory is dirty.' "$main_branch"
                    exit 2
                else
                    info 'Checking out `%s`...' "$main_branch"
                    run git checkout "$main_branch"
                    info 'done.'
                fi
                ;;
            stay)
                if [ -n "$current_branch" ]; then
                    info 'This script will only pull from and push to `%s`.' "$current_branch"
                fi
                ;;
            abort)
                info 'Aborting.'
                exit 2
                ;;
            *)
                error 'Unexpected action if the branch is not `%s`: `%s`.' "$main_branch" "$action_if_not_main"
                exit 3
        esac
    fi
}

## ===================== [ Update the local repository ] ===================== ##

repo_update ()
{
    if $update; then
        if $is_dirty; then
            error 'Cannot update when working directory is dirty.'
            exit 2
        fi
        if [ -z "$current_branch" ]; then
            error 'Cannot update when in detached state.'
            exit 2
        fi
        info 'Updating the configuration repository...'
        run git pull --ff-only
        info 'done.'
    fi
}

## ===================== [ Actually perform the action ] ===================== ##

rebuild_home ()
{
    info 'Rebuilding Home configuration...'

    run home-manager \
        --extra-experimental-features 'nix-command flakes' \
        switch --impure --flake "$local_repo"\#"$home_profile"

    echo "$home_profile" >| "$local_repo"/.home-profile

    info 'done.'
}

rebuild_deploy ()
{
    info 'Rebuilding and deploying `%s`...' "$target"

    if target_host_output=$(nix eval --impure --raw --expr "
            let m = (import ./machines.nix).servers.$target; in
            m.ipv4 or m.ipv6 or \"$target.niols.fr\"
        ")
    then
        target_host=root@$target_host_output
        info 'Recognising target `%s` as host `%s`.' "$target" "$target_host"
    else
        error 'Something went wrong when finding the target host. Probably, the machine does not exist or is not a server?'
        exit 2
    fi
    readonly target_host

    run nixos-rebuild $action --target-host "$target_host" --flake "$local_repo"\#"$target" --elevate=sudo

    info 'done.'
}

rebuild_nixos ()
{
    info 'Rebuilding NixOS configuration...'

    if ! [ -e /etc/NIXOS ]; then
        warning 'This does not look like a NixOS machine. Do you mean to run this script with --home-profile?'
    fi

    nixos-rebuild $action --flake "$local_repo" --elevate=sudo

    info 'done.'
}

rebuild ()
{
    if [ -n "$home_profile" ]; then
        rebuild_home
    elif [ -n "$target" ]; then
        rebuild_deploy
    else
        rebuild_nixos
    fi
}

## ==================== [ Tagging the local repository ] ===================== ##

repo_tag ()
{
    if $is_dirty; then
        info 'Not adding a Git tag for the current generation, because the working directory is dirty.'

    elif current_commit_again=$(get_current_commit); [ "$current_commit_again" != "$current_commit" ]; then
        warning 'Commit has changed during rebuild (from %s to %s); not adding a Git tag because it is unclear what has been rebuilt.' \
                "$current_commit" "$current_commit_again"

    else
        info 'Adding a Git tag for the current generation...'
        [ -z "$target" ] && hostname=$(hostname -s) || hostname=$target

        if [ -z "$home_profile" ]; then
            if [ -z "$target" ]; then
                output=$(nixos-rebuild list-generations --json)
            else
                output=$(ssh "$target_host" nixos-rebuild list-generations --json)
            fi
            output=$(echo "$output" | jq '.[] | select(.current == true)')
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
        run git tag "$tag" "$current_commit" --message="$description"
        info 'done.\nPushing changes to remote...'
        run git push --tags
        info 'done.'
    fi
}

## ======================== [ Suggesting to reboot ] ========================= ##

maybe_reboot ()
{
    if [ "$action" != switch ] && [ -z "$home_profile" ]; then
        ask answer 'Do you wish to reboot? (y/N)'
        # shellcheck disable=SC2154
        if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
            info 'Rebooting...'

            if [ -n "$target" ]; then
                run ssh "$target_host" reboot
            else
                run reboot
            fi
        fi
    fi
}

## =========================== [ The actual loop ] =========================== ##

info 'Welcome!'

parse_cli "$@"
repo_setup
repo_check_dirty
repo_check_branch_commit
repo_update
rebuild
repo_tag
maybe_reboot

info 'All done!'
