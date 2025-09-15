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

    ## If there is a MOTD and we are not entering a Nix shell, then we print the
    ## MOTD in question.
    ##
    if [ -f /var/run/motd.dynamic ] && ! [ -n "$IN_NIX_SHELL" ]; then
      cat /var/run/motd.dynamic
    fi
  '';
}
