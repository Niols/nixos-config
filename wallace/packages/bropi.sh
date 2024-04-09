#!/bin/sh
set -euC

## Check for required commands.
if ! command -v zenity >/dev/null
then
    printf >&2 'This script requires `zenity` to run properly. Exiting.\n'
    exit 2
fi

## Check whether the given first argument is a running process. This check is
## simplistic as it will capture processes that contain a browser's name. We are
## hoping that the browsers' names are specific enough and that nobody is
## running eg. `firefoxy` or `a-process --arg=firefox`.
is_running () {
    ps -e | grep -q "$1"
}

## Convert the given input to lowercase.
lowercase () {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

## Find all desktop files in given directory that have `WebBrowser` in their
## `Categories` field (except BroPi's) and extract their `Name` field. This
## script assumes that the executable name is the lowercase version of the
## `Name` field, which is, of course, quite simplistic.
find_browsers () {
    echo "${XDG_DATA_DIRS-/usr/local/share:/usr/share}" | \
        tr ':' '\n' | \
        while read -r dir; do
            find "$dir" \
                -name '*.desktop' \
                -exec grep 'Categories=.*WebBrowser' {} + \
                2>/dev/null \
                | cut -d : -f 1 \
                | grep -v bropi.desktop \
                | xargs -n1 sed -n '/\[Desktop Entry\]/,/\[/{s/^Name=\(.*\)$/\1/p}'
        done | \
        sort -u
}

## Constant that contains all the browsers to try.
readonly browsers=$(find_browsers)
printf >&2 'Browsers to try: %s\n' "$(echo "$browsers" | tr '\n' ' ')"

## Variable which we aim to fill with the right browser.
the_browser=

## Try to find _the_ browser automatically by finding the only browser from the
## list above that is running.

printf >&2 'Checking if a unique browser is running...\n'
for browser in $browsers
do
    if is_running $(lowercase $browser)
    then
        if [ -z $the_browser ]
        then
            ## This is the first running browser we see; a great candidate to be
            ## _the_ browser!
            printf >&2 -- '- %s is running; a good candidate.\n' $browser
            the_browser=$(lowercase $browser)
        else
            ## Ooops, several browser are running. We have not found out _the_
            ## browser in an automated way; revert and give up.
            printf >&2 -- '- %s is also running; whoopsie-daisy!\n' $browser
            the_browser=
            break
        fi
    else
        printf >&2 -- '- %s is not running.\n' $browser
    fi
done

if [ -z $the_browser ]
then
    ## Dayum; there was either no or several browsers running. We need to ask
    ## the user:

    printf >&2 'Could not decide automatically; asking the user...\n'
    the_browser=$(
        zenity \
            --info \
            --icon=dialog-question \
            --title="Pick browser" \
            --text="$(printf 'Either no or several browsers are running. Choose which one to open with the arguments:\n\n%s\n' "$*")" \
            --ok-label="Cancel" \
            $(for browser in $browsers; do echo --extra-button=$browser; done) \
            || :
    )

    if [ -z $the_browser ]
    then
        ## Even asking the user did not succeed; they pressed Esc or clicked
        ## Cancel. Give up gracefully.
        printf >&2 'The user cancelled. Exiting.\n'
        exit 1
    else
        printf >&2 'The user answered: %s.\n' $the_browser
        the_browser=$(lowercase $the_browser)
    fi
fi

printf >&2 'Running: %s %s\n' $the_browser "$*"
exec $the_browser "$@"
