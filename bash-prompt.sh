readonly HISTTIMEFORMAT='%s '

## FIXME: missing "not bold", "not underlined", "not blinking", "not
## inverse", "not hidden", "foreground reset", "background reset", and
## probably others.

bp_colour () {
    printf '\e[%sm' "$1" | \
	sed -e 's|,|;|g' \
	    -e 's|reset|0|' \
	    -e 's|bold|1|' \
	    -e 's|faint|2|' \
	    -e 's|italic|3|' \
	    -e 's|underlined|4|' \
	    -e 's|fg:black|30|' \
	    -e 's|bg:black|40|' \
	    -e 's|fg:red|31|' \
	    -e 's|bg:red|41|' \
	    -e 's|fg:green|32|' \
	    -e 's|bg:green|42|' \
	    -e 's|fg:yellow|33|' \
	    -e 's|bg:yellow|43|' \
	    -e 's|fg:blue|34|' \
	    -e 's|bg:blue|44|' \
	    -e 's|fg:magenta|35|' \
	    -e 's|bg:magenta|45|' \
	    -e 's|fg:cyan|36|' \
	    -e 's|bg:cyan|46|' \
	    -e 's|fg:lightgray|37|' \
	    -e 's|bg:lightgray|47|' \
	    -e 's|fg:gray|90|' \
	    -e 's|bg:gray|100|' \
	    -e 's|fg:lightred|91|' \
	    -e 's|bg:lightred|101|' \
	    -e 's|fg:lightgreen|92|' \
	    -e 's|bg:lightgreen|102|' \
	    -e 's|fg:lightyellow|93|' \
	    -e 's|bg:lightyellow|103|' \
	    -e 's|fg:lightblue|94|' \
	    -e 's|bg:lightblue|104|' \
	    -e 's|fg:lightmagenta|95|' \
	    -e 's|bg:lightmagenta|105|' \
	    -e 's|fg:lightcyan|96|' \
	    -e 's|bg:lightcyan|106|' \
	    -e 's|fg:white|97|' \
	    -e 's|bg:white|107|'
}

## ==================== [ Report ] ==================== ##

bp_return_code () {
    _bp_rc=$?
    if [ $_bp_rc -eq 0 ]; then
	bp_colour reset,bold,fg:green
	printf '✓ 0'
	bp_colour reset
    else
	bp_colour reset,bold,fg:red
	printf '✗ %d' $_bp_rc
	bp_colour reset
    fi
}

bp_time () {
    _bp_start=$(history 1 | { read _ t _; echo $t; })
    _bp_end=$(date +%s)
    _bp_duration=$((_bp_end - _bp_start))
    bp_colour fg:lightgray
    printf ' in %s' "$(date +%M:%S -ud@$_bp_duration)"
}

bp_report_line () {
    bp_return_code
    bp_time
}

## ==================== [ Status Line ] ==================== ##

bp_first_sep () {
    # bp_colour fg:black,bg:$2
    # printf '▌'
    bp_colour fg:$1,bg:$2
}

bp_sep () {
    bp_colour fg:black
    printf '▐'
    bp_colour bg:$2
    printf '▌'
    bp_colour fg:$1,bg:$2
}

bp_last_sep () {
    bp_colour fg:black
    printf '▐'
}

## All functions leave their background hanging for the separator to
## use. They handle the separator by giving it the color that will be
## the background

bp_user () {
    [ $(id -u) -eq 0 ] && bp_first_sep black lightred \
                       || bp_first_sep black lightgreen
    printf '%s@%s' $(id -nu) $(hostname)
}

bp_pwd () {
    bp_sep white gray
    printf '%s' "${PWD/#$HOME/'~'}"
}

bp_git_descr () {
    printf '%s' $(git describe --all --always --abbrev=7 2>/dev/null \
                    | sed 's|^heads/||')
    if [ -n "$(git status --short 2>/dev/null)" ]; then
        printf ' (dirty)'
    fi
}
bp_git () {
    _bp_git_descr_out=$(bp_git_descr)
    if [ -n "$_bp_git_descr_out" ]; then
	bp_sep black lightyellow
        printf 'git: %s' "$_bp_git_descr_out"
    fi
}

bp_nix () {
    if [ -n "${IN_NIX_SHELL+x}" ]; then
	bp_sep black lightcyan
        printf 'nix: %s' "$IN_NIX_SHELL"
    fi
}

bp_status_line () {
    printf '%s%s%s%s%s%s' \
	   "$(bp_user)" \
	   "$(bp_pwd)" \
	   "$(bp_git)" \
	   "$(bp_nix)" \
	   "$(bp_last_sep)" \
	   "$(bp_colour reset)"
}

## ==================== [ Prompt ] ==================== ##

bp_prompt () {
    if [ $(id -u) -eq 0 ]; then
        printf '# '
    else
        printf '$ '
    fi
}

## ==================== [ Finally ] ==================== ##

export PS1="\n\$(bp_report_line)\n\$(bp_status_line)\n\$(bp_prompt)"
