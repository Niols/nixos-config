{
  enable = true;

  bashrcExtra = ''
    ## Keep the prompt when entering `nix shell`.
    ##
    ## NOTE: We put this here instead of in
    ## `home.sessionVariables` because the latter only works for
    ## login Shells.
    ##
    ## cf https://discourse.nixos.org/t/*/8488/23
    ##
    NIX_SHELL_PRESERVE_PROMPT=yes

    ## The `nrun` command tries to find the given command name for you,
    ## either by pulling it from the `PATH` (although you probably already
    ## tried that) or by pulling it from the `nixpkgs` flake.
    ##
    nrun () (
      cmd=$1; shift
      if command -v "$cmd" >/dev/null; then
        "$cmd" "$@"
      elif nix search nixpkgs "^$cmd\$" >/dev/null 2>&1; then
        nix run nixpkgs#"$cmd" -- "$@"
      else
        echo "Command '$cmd' could not be found in the system or in nixpkgs." >&2
        exit 127
      fi
    )

    ## If there is a MOTD and we are not entering a Nix shell, then we print the
    ## MOTD in question.
    ##
    if [ -f /var/run/motd.dynamic ] && ! [ -n "$IN_NIX_SHELL" ]; then
      cat /var/run/motd.dynamic
    fi
  '';
}
