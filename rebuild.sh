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
die () { error "$@"; exit 2; }
# shellcheck disable=SC2059,SC2229
ask () { var=$1; shift; fmt=$1; shift; printf "\e[37m\e[1m[ASK]\e[22m $fmt\e[0m " "$@"; read -r "$var"; }

## ======================== [ Command line parsing ] ========================= ##

usage () {
    cat <<EOF
Usage: $0 <action> [option ...]

<action> can be one of:

    switch    install a NixOS configuration and activate it (default)
    boot      install a NixOS configuration as default boot entry
    home      run a Home Manager installation
    deploy    build and deploy a NixOS configuration

home-specific [option]:

    --profile, -p <s>   install the home profile <s> (default: autodetect)

deploy-specific [option]:

    --target, -t <s>    deploy the target machine <s>. this option can be repeated to
                        deploy several machines. (default: deploy all machines)

[option] can be one of:

    --dirty, -d         proceed even if the repository is dirty (default: ask)
    --main, -m          checkout main if on another branch (default: ask)
    --stay, -s          stay on the branch if it is not main (default: ask)
    --update, -u        pull the configuration before rebuilding (default: do not update)
    --dry-run           do not actually build or deploy anything
    --help, -h          show this help and exit
EOF

    exit "$1"
}

die_with_usage () { error "$@"; usage 2; }

parse_cli ()
{
    action=switch
    home_profile=
    deploy_targets=

    update=false
    dry_run=false

    wtd_if_dirty=ask
    wtd_if_not_main=ask

    while [ $# -gt 0 ]; do
        case $1 in
            switch) action=switch ;;
            boot) action=boot ;;
            home) action=home ;;
            deploy) action=deploy ;;

            --profile|-p)
                [ "$action" != home ] && die '--profile must be placed after the `home` action.'
                [ -n "$home_profile" ] && die '--profile can only be specified one.'
                shift; home_profile=$1
                ;;

            --target|-t)
                [ "$action" != deploy ] && die '--deploy must be placed after the `deploy` action.'
                shift; deploy_targets="$deploy_targets $1"
                ;;

            --update|-u) update=true ;;
            --dry-run) dry_run=true ;;

            --dirty|-d) wtd_if_dirty=proceed ;;
            --main|-m) wtd_if_not_main=checkout ;;
            --stay|-s) wtd_if_not_main=stay ;;

            --help|-h) usage 0 ;;
            *) die_with_usage 'Unexpected argument: %s\n' "$1" ;;
        esac
        shift
    done

    readonly action
    readonly update
    readonly dry_run

    if [ "$action" = home ] && [ -z "$home_profile" ]; then
        if [ -e "$local_repo"/.home-profile ]; then
            home_profile=$(cat "$local_repo"/.home-profile)
            info 'Detected a Home Manager installation; will use home profile `%s`.' "$home_profile"
        else
            die_with_usage 'Could not detect a Home Manager installation; specify it with --profile.'
        fi
    fi
    readonly home_profile

    if [ "$action" = deploy ] && [ -z "$deploy_targets" ]; then
        ## FIXME: grab all targets
        info 'No deploy targets specified, will deploy: %s.' "$deploy_targets"
    fi
    readonly deploy_targets
}

## ======================= [ Set up helper functions ] ======================= ##

run () {
    printf '\e[36m\e[1m[RUN] %s\e[0m\n' "$*"
    if ! $dry_run; then "$@"; fi
}

target_host () {
    echo root@"$1".niols.fr ## FIXME: IP from machines.nix?

        # if target_host_output=$(nix eval --impure --raw --expr "
        #     let m = (import ./machines.nix).servers.$target; in
        #     m.ipv4 or m.ipv6 or \"$target.niols.fr\"
        # ")
}

on_target () {
    target=$1; shift
    ssh "$(target_host "$target")" -- "$@"
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
        if [ $wtd_if_dirty = ask ]; then
            ask response 'Do you want to \e[1m[p]\e[22mroceed anyway or \e[1m[a]\e[22mbort?'
            # shellcheck disable=SC2154
            case $response in
                p)
                    info 'You can also pass the --dirty argument to do this automatically.'
                    wtd_if_dirty=proceed
                    ;;
                a)
                    wtd_if_dirty=abort
                    ;;
                *)
                    die 'Unexpected response: `%s`.' "$response"
            esac
        fi
        case $wtd_if_dirty in
            proceed)
                info 'Proceeding. Some functionalities, such as tagging, will not be available.'
                ;;
            abort)
                info 'Aborting.'
                exit 2
                ;;
            *)
                error 'Unexpected instruction when the repository is dirty: `%s`.' "$wtd_if_dirty"
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

        if [ $wtd_if_not_main = ask ]; then
            [ -n "$current_branch" ] && on_current_branch=$(printf 'on `%s`' "$current_branch") || on_current_branch=detached
            ask response 'Do you want to \e[1m[c]\e[22mheckout `%s`, \e[1m[s]\e[22mtay %s, or \e[1m[a]\e[22mbort?' "$main_branch" "$on_current_branch"
            # shellcheck disable=SC2154
            case $response in
                c)
                    info 'You can also pass the --main argument to do this automatically.'
                    wtd_if_not_main=checkout
                    ;;
                s)
                    info 'You can also pass the --stay argument to do this automatically.'
                    wtd_if_not_main=stay
                    ;;
                a)
                    wtd_if_not_main=abort
                    ;;
                *)
                    die 'Unexpected response: `%s`.' "$response"
            esac
        fi

        case $wtd_if_not_main in
            checkout)
                $is_dirty && die 'Cannot checkout `%s` when working directory is dirty.' "$main_branch"
                info 'Checking out `%s`...' "$main_branch"
                run git checkout "$main_branch"
                info 'done.'
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
                die 'Unexpected instruction when the branch is not `%s`: `%s`.' "$main_branch" "$wtd_if_not_main"
        esac
    fi
}

## ===================== [ Update the local repository ] ===================== ##

repo_update ()
{
    if $update; then
        $is_dirty && die 'Cannot update when working directory is dirty.'
        [ -z "$current_branch" ] && die 'Cannot update when in detached state.'
        info 'Updating the configuration repository...'
        run git pull --ff-only
        info 'done.'
    fi
}

## ===================== [ Actually perform the action ] ===================== ##

rebuild_nixos ()
{
    if [ "$action" = boot ] || [ "$action" = switch ]; then
        info 'Rebuilding NixOS configuration...'
        if ! [ -e /etc/NIXOS ]; then
            warning 'This does not look like a NixOS machine. Do you mean to run this script with --home-profile?'
        fi
        run sudo true # check sudo privileges ahead of time
        run nixos-rebuild $action --flake "$local_repo" --elevate=sudo
        info 'done.'
    fi
}

rebuild_home ()
{
    if [ "$action" = home ]; then
        info 'Rebuilding Home configuration...'
        run home-manager \
            --extra-experimental-features 'nix-command flakes' \
            switch --impure --flake "$local_repo"\#"$home_profile"
        echo "$home_profile" >| "$local_repo"/.home-profile
        info 'done.'
    fi
}

deploy_machines ()
{
    if [ "$action" = deploy ]; then
        info 'Rebuilding and deploying %s...' "$deploy_targets"
        for deploy_target in $deploy_targets; do
            info 'Rebuilding and deploying `%s`...' "$deploy_target"
            run nixos-rebuild $action --target-host "$(target_host "$deploy_target")" --flake "$local_repo"\#"$deploy_target" --elevate=sudo
            info 'done deploying this target.'
        done
        info 'done deploying all targets.'
    fi
}

## ==================== [ Tagging the local repository ] ===================== ##

tag_this ()
{
    tag=$1
    description=$2

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

    info 'done.'
}

tag_this_nixos ()
{
    hostname=$1
    output=$(echo "$2" | jq '.[] | select(.current == true)')
    [ -z "$output" ] && die 'No current generation found.'
    generation=$(echo "$output" | jq -r .generation)
    date=$(echo "$output" | jq -r .date | cut -d ' ' -f 1)
    nixosVersion=$(echo "$output" | jq -r .nixosVersion)
    tag_this \
        "nixos-$hostname-gen-$generation" \
        "NixOS configuration \`$hostname\` — generation $generation ($date - $nixosVersion)"
}

tag_nixos ()
{
    if [ "$action" = boot ] || [ "$action" = switch ]; then
        output=$(nixos-rebuild list-generations --json)
        tag_this_nixos "$(hostname -s)" "$output"
    fi
}


tag_deploy ()
{
    if [ "$action" = deploy ]; then
        for deploy_target in $deploy_targets; do
            output=$(on_target "$deploy_target" nixos-rebuild list-generations --json)
            tag_this_nixos "$deploy_target" "$output"
        done
    fi
}

tag_home ()
{
    if [ "$action" = home ]; then
        generation=$(home-manager generations | grep '(current)' | cut -d ' ' -f 5)
        if ! [[ "$generation" =~ ^[0-9]+$ ]]; then die 'Could not find the Home generation.'; fi
        date=$(date +'%Y-%m-%d')
        tag_this \
            "home-$home_profile-on-$hostname-gen-$generation" \
            "Home configuration \`$home_profile\` on \`$hostname\` — generation $generation ($date)"
    fi
}


tag ()
{
    if $is_dirty; then
        info 'Not adding a Git tag for the current generation, because the working directory is dirty.'

    elif current_commit_again=$(get_current_commit); [ "$current_commit_again" != "$current_commit" ]; then
        warning 'Commit has changed during rebuild (from %s to %s); not adding a Git tag because it is unclear what has been rebuilt.' \
                "$current_commit" "$current_commit_again"

    else
        info 'Adding a Git tag for the current generation...'

        tag_nixos
        tag_deploy
        tag_home

        info 'Pushing changes to remote...'
        run git push --tags
        info 'done.'
    fi
}

## ======================== [ Suggesting to reboot ] ========================= ##

reboot_local_machine ()
{
    if [ "$action" != switch ] && [ -z "$home_profile" ]; then
        ask answer 'Do you wish to reboot? (y/N)'
        # shellcheck disable=SC2154
        if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
            info 'Rebooting...'
            run reboot
        fi
    fi
}

reboot_remote_machines ()
{
    if [ "$action" = deploy ]; then
        ask answer 'Do you wish to reboot the remote machine(s)? (y/N)'
        # shellcheck disable=SC2154
        if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
            info 'Rebooting...'
            for deploy_target in $deploy_targets; do
                on_target "$deploy_target" reboot
            done
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

rebuild_nixos
rebuild_home
deploy_machines

tag

reboot_local_machine
reboot_remote_machines

info 'All done!'
