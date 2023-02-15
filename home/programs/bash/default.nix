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

    ## Removes all the `.direnv/flake-profile-*-link` files that are not the one
    ## pointed by `.direnv/flake-profile`.
    ##
    cleanup_flake_profiles () {
      find . \
          -type l \
          -regex '.*/.direnv/flake-profile-[0-9]*-link' \
          -exec sh -c 'a={}; b=''${a%-[0-9]*-link}; ! [ $a -ef $b ]' ';' \
          -delete
    }
  '';
}