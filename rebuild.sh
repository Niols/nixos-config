set -euC

## ============================== [ Constants ] ============================== ##

github_repo=niols/nixos-config
local_repo=~/.config/nixos
main_branch=main
number_of_ssh_attempts=50

readonly github_repo local_repo main_branch number_of_ssh_attempts

## ========================== [ Loggers & helpers ] ========================== ##

# shellcheck disable=SC2059
info () { fmt=$1; shift; printf >&2 "\e[37m[INF] $fmt\e[0m\n" "$@"; }
# shellcheck disable=SC2059
warning () { fmt=$1; shift; printf >&2 "\e[33m\e[1m[WRN] $fmt\e[0m\n" "$@"; }
# shellcheck disable=SC2059
error () { fmt=$1; shift; printf >&2 "\e[31m\e[1m[ERR] $fmt\e[0m\n" "$@"; }
die () { error "$@"; exit 2; }
# shellcheck disable=SC2059,SC2229
ask () { var=$1; shift; fmt=$1; shift; printf "\e[37m\e[1m[ASK]\e[22m $fmt\e[0m " "$@"; read -r "$var"; }

## ======================== [ Command line parsing ] ========================= ##

usage () {
    cat <<EOF >&2
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

    --clone, -c         if the local repository doesn't exist, clone it (default: ask)
    --dirty, -d         proceed even if the local repository is dirty (default: ask)
    --dry-run           do not actually build or deploy anything
    --flake, -f <local|github|embedded|cwd>
                        use the flake from the given source (default: local)
    --main, -m          checkout main if the local repository is on another branch (default: ask)
    --reboot, -r        reboot the machine/s at the end (default: ask)
    --no-reboot, -nr    do not reboot the machine/s at the end (default: ask)
    --stay, -s          stay on the branch if the local repository is not on main (default: ask)
    --update, -u        pull the configuration of the local repository before rebuilding
    --help, -h          show this help and exit
EOF

    exit "$1"
}

die_with_usage () { error "$@"; printf >&2 '\n'; usage 2; }

parse_cli ()
{
    action=switch
    home_profile=
    deploy_targets=
    flake_source=local

    update=false
    dry_run=false

    wtd_if_absent=ask
    wtd_if_dirty=ask
    wtd_if_not_main=ask
    wtd_reboot=ask

    while [ $# -gt 0 ]; do
        case $1 in
            switch) action=switch ;;
            boot) action=boot ;;
            home) action=home ;;
            deploy) action=deploy ;;

            --profile|-p)
                [ "$action" != home ] && die_with_usage '--profile must be placed after the `home` action.'
                [ -n "$home_profile" ] && die_with_usage '--profile can only be specified once.'
                shift; home_profile=$1
                ;;

            --target|-t)
                [ "$action" != deploy ] && die_with_usage '--deploy must be placed after the `deploy` action.'
                shift; deploy_targets="$deploy_targets $1"
                ;;

            --flake|-f)
                shift
                [ "$flake_source" != local ] && die_with_usage '--flake can only be specified once.'
                case $1 in
                    local) flake_source=local ;;
                    github|embedded|cwd) wtd_if_absent=nothing; flake_source=$1 ;;
                    *) die_with_usage 'Unexpected flake source: `%s`' ;;
                esac
                ;;

            --update|-u) update=true ;;
            --dry-run) dry_run=true ;;

            --clone|-c) wtd_if_absent=clone ;;
            --dirty|-d) wtd_if_dirty=proceed ;;
            --main|-m) wtd_if_not_main=checkout ;;
            --stay|-s) wtd_if_not_main=stay ;;
            --reboot|-r) wtd_reboot=reboot ;;
            --no-reboot|-nr) wtd_reboot=nothing ;;

            --help|-h) usage 0 ;;
            *) die_with_usage 'Unexpected argument: `%s`' "$1" ;;
        esac
        shift
    done

    readonly action
    readonly update
    readonly dry_run
    readonly flake_source

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
        deploy_targets=" $__nix__all_deploy_targets"
        info 'No deploy targets specified, will deploy:%s.' "$deploy_targets"
    fi
    readonly deploy_targets
}

## ======================= [ Set up helper functions ] ======================= ##

run () {
    printf '\e[36m\e[1m[RUN] %s\e[0m\n' "$*"
    if ! $dry_run; then "$@"; fi
}

deploy_target_gen () {
    if eval "[ -n \"\${__nix__deploy_target_$1__$2+x}\" ]"; then
        eval "echo \"\$__nix__deploy_target_$1__$2\""
    else
        die 'Unknown target: `%s`' "$2"
    fi
}

deploy_target_host () { deploy_target_gen host "$@"; }

deploy_target_userhost () {
    user=$(deploy_target_gen user "$@")
    host=$(deploy_target_gen host "$@")
    echo "$user@$host"
}

on_target () {
    target=$1; shift
    ssh "$(deploy_target_userhost "$target")" -- "$@"
}

in_local_repo () {
    (cd "$local_repo" && "$@")
}

## ===================== [ Set up the local repository ] ===================== ##

repo_setup ()
{
    if [ -e "$local_repo" ]; then
        local_repo_is_present=true
    else
        local_repo_is_present=false
    fi

    if ! $local_repo_is_present; then
        info 'The local repository is absent.'

        if [ $wtd_if_absent = ask ]; then
            ask response 'Do you want to \e[1m[c]\e[22mlone it, use the \e[1m[e]\e[22mmbedded flake, or use the flake from \e[1m[g]\e[22mithub?'
            # shellcheck disable=SC2154
            case $response in
                c)
                    info 'You can also pass the --clone argument to do this automatically.'
                    wtd_if_absent=clone
                    ;;
                e)
                    wtd_if_absent=nothing
                    flake_source=embedded
                    ;;
                g)
                    wtd_if_absent=nothing
                    flake_source=github
                    ;;
                *)
                    die 'Unexpected response: `%s`.' "$response"
            esac
        fi

        case $wtd_if_absent in
            clone)
                info 'Cloning the github repository locally...'
                mkdir -p "$(dirname "$local_repo")"
                run in_local_repo git clone git@github.com:"$github_repo".git "$local_repo"
                info 'done.'
                local_repo_is_present=true
                ;;
            nothing)
                true # do nothing
                ;;
            *)
                die 'Unexpected instruction when the repository is absent: `%s`.' "$wtd_if_absent"
        esac
    fi

    case $flake_source in
        local) flake=$local_repo ;;
        embedded) flake=$__nix__flake_root ;;
        github) flake=github:$github_repo ;;
        cwd) flake=$PWD ;;
        *) die 'Unexpected flake source: `%s`.' "$flake_source"
    esac

    readonly local_repo_is_present flake
}

## ================== [ Check if the repository is dirty ] =================== ##

repo_check_dirty ()
{
    if [ -n "$(in_local_repo git status --porcelain)" ]; then is_dirty=true; else is_dirty=false; fi
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

get_current_branch () { in_local_repo git branch --show-current; }
get_current_commit () { in_local_repo git log --max-count=1 --format=%h; }

repo_check_branch_commit ()
{
    current_branch=$(get_current_branch)
    current_commit=$(get_current_commit)
    readonly current_branch current_commit

    if [ "$current_branch" = "$main_branch" ]; then
        return
    fi

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
            run in_local_repo git checkout "$main_branch"
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
}

## ===================== [ Update the local repository ] ===================== ##

repo_update ()
{
    ! $local_repo_is_present && die 'Cannot update when there is no local repository.'
    $is_dirty && die 'Cannot update when working directory is dirty.'
    [ -z "$current_branch" ] && die 'Cannot update when in detached state.'

    info 'Updating the configuration repository...'
    run in_local_repo git pull --ff-only
    info 'done.'
}

## ===================== [ Actually perform the action ] ===================== ##

rebuild_nixos ()
{
    if ! [ "$action" = boot ] && ! [ "$action" = switch ]; then
        return
    fi

    info 'Rebuilding NixOS configuration...'
    if ! [ -e /etc/NIXOS ]; then
        warning 'This does not look like a NixOS machine. Do you mean to run this script with --home-profile?'
    fi
    run sudo true # check sudo privileges ahead of time
    run nixos-rebuild $action --flake "$flake" --elevate=sudo
    info 'done.'
}

rebuild_home ()
{
    info 'Rebuilding Home configuration...'

    run home-manager \
        --extra-experimental-features 'nix-command flakes' \
        switch --impure --flake "$flake"\#"$home_profile"

    if $local_repo_is_present; then
        echo "$home_profile" >| "$local_repo"/.home-profile
    fi

    info 'done.'
}

deploy_machines ()
{
    for deploy_target in $deploy_targets; do
        info 'Rebuilding and deploying %s...' "$deploy_target"
        run nixos-rebuild boot --target-host "$(deploy_target_userhost "$deploy_target")" --flake "$flake"\#"$deploy_target" --elevate=sudo
        info 'done deploying %s.' "$deploy_target"
    done
}

## ==================== [ Tagging the local repository ] ===================== ##

tag_this ()
{
    tag=$1
    description=$2

    if [ -n "$(in_local_repo git tag --list "$tag")" ]; then
        info 'The tag already exists. This means that you rebuilt something that did not change the configuration at all. Tagging anyway...'
        rebuild_number=2
        tag_with_rebuild=$tag-rebuild-$rebuild_number
        while [ -n "$(in_local_repo git tag --list "$tag_with_rebuild")" ]; do
            rebuild_number=$((rebuild_number + 1))
            tag_with_rebuild=$tag-rebuild-$rebuild_number
        done
        tag=$tag_with_rebuild
    fi

    info 'Tagging as: %s\nwith description: %s.' "$tag" "$description"
    run in_local_repo git tag "$tag" "$current_commit" --message="$description"

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
    output=$(nixos-rebuild list-generations --json)
    tag_this_nixos "$(hostname -s)" "$output"
}

tag_deploy ()
{
    for deploy_target in $deploy_targets; do
        output=$(on_target "$deploy_target" nixos-rebuild list-generations --json)
        tag_this_nixos "$deploy_target" "$output"
    done
}

tag_home ()
{
    generation=$(home-manager generations | grep '(current)' | cut -d ' ' -f 5)
    if ! [[ "$generation" =~ ^[0-9]+$ ]]; then die 'Could not find the Home generation.'; fi
    date=$(date +'%Y-%m-%d')
    tag_this \
        "home-$home_profile-on-$hostname-gen-$generation" \
        "Home configuration \`$home_profile\` on \`$hostname\` — generation $generation ($date)"
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

        case $action in
            boot|switch) tag_nixos ;;
            home) tag_home ;;
            deploy) tag_deploy ;;
        esac

        info 'Pushing changes to remote...'
        run in_local_repo git push --tags
        info 'done.'
    fi
}

## ======================== [ Suggesting to reboot ] ========================= ##

reboot_gen ()
{
    details=$1; shift

    if [ "$wtd_reboot" = ask ]; then
        ask answer 'Do you wish to reboot%s? (y/N)' "$details"
        # shellcheck disable=SC2154
        if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
            wtd_reboot=reboot
        else
            wtd_reboot=nothing
        fi
    fi

    case $wtd_reboot in
        reboot) info 'Rebooting...'; "$@" ;;
        nothing) : ;;
        *) die 'Unexpected instruction to reboot: `%s`.' "$wtd_reboot" ;;
    esac
}

reboot_remote_machines_callback ()
{
    for deploy_target in $deploy_targets; do
        run on_target "$deploy_target" reboot
    done
    info 'Done.'

    sleep 1
    info 'Waiting for machines to be up...'

    for deploy_target in $deploy_targets; do
        has_printed_a_dot=false
        is_up=false

        for _ in $(seq $number_of_ssh_attempts); do
            if nc -z -w2 "$(deploy_target_host "$deploy_target")" 22 2>/dev/null; then
                is_up=true
                break
            else
                printf .; has_printed_a_dot=true
                sleep 2
            fi
        done

        $has_printed_a_dot && printf '\n'

        if $is_up; then
            info 'Machine `%s` is up.' "$deploy_target"
        else
            warning 'Machine `%s` is still not up after %d attempts. Giving up.' "$deploy_target" $number_of_ssh_attempts
        fi
    done
}

reboot_local_machine () {
    reboot_gen '' run reboot
}

reboot_remote_machines () {
    reboot_gen ' the remote machine/s' reboot_remote_machines_callback
}

## =========================== [ The actual loop ] =========================== ##

info 'Welcome!'

parse_cli "$@"

repo_setup

if $local_repo_is_present; then
    repo_check_dirty
    repo_check_branch_commit
fi
if $update; then
    repo_update
fi

case $action in
    boot|switch) rebuild_nixos ;;
    home) rebuild_home ;;
    deploy) deploy_machines ;;
esac

if $local_repo_is_present; then
    tag
fi

case $action in
    boot) reboot_local_machine ;;
    deploy) reboot_remote_machines ;;
esac

info 'All done!'
